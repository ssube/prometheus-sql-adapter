// Copyright 2015 The Prometheus Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package postgres

import (
	"crypto/sha1"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"math"
	"time"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/lib/pq"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/common/model"
	"github.com/robfig/cron/v3"
)

// Client allows sending batches of Prometheus samples to Postgres.
type Client struct {
	logger log.Logger

	db   *sql.DB
	cron *cron.Cron
}

var (
	maxOpenConns = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name:      "open_max",
			Namespace: "adapter",
			Subsystem: "connections",
			Help:      "Maximum number of open connections to the database.",
		},
		[]string{"remote"},
	)
	curOpenConns = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name:      "open_current",
			Namespace: "adapter",
			Subsystem: "connections",
			Help:      "Current number of open connections to the database.",
		},
		[]string{"remote"},
	)
	curIdleConns = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name:      "idle_current",
			Namespace: "adapter",
			Subsystem: "connections",
			Help:      "Current number of idle connections to the database.",
		},
		[]string{"remote"},
	)
	curUsedConns = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name:      "used_current",
			Namespace: "adapter",
			Subsystem: "connections",
			Help:      "Current number of actively used connections to the database.",
		},
		[]string{"remote"},
	)

	labels_nothing = "INSERT INTO metric_labels(lid, time, labels) VALUES ( $1, $2, $3 ) ON CONFLICT (lid) DO NOTHING"
	labels_update  = "INSERT INTO metric_labels(lid, time, labels) VALUES ( $1, $2, $3 ) ON CONFLICT (lid) DO UPDATE SET time = EXCLUDED.time"
)

func init() {
	prometheus.MustRegister(curIdleConns)
	prometheus.MustRegister(curUsedConns)
	prometheus.MustRegister(curOpenConns)
	prometheus.MustRegister(maxOpenConns)
}

// NewClient creates a new Client.
func NewClient(logger log.Logger, conn string, idle int, open int) *Client {
	if logger == nil {
		logger = log.NewNopLogger()
	}
	db, err := sql.Open("postgres", conn)
	if err != nil {
		level.Error(logger).Log("msg", "error opening database connection", "err", err)
		return nil
	}
	db.SetMaxIdleConns(idle)
	db.SetMaxOpenConns(open)

	cr := cron.New(cron.WithSeconds())
	c := &Client{
		cron:   cr,
		logger: logger,
		db:     db,
	}

	cr.AddFunc("@every 15s", func() {
		c.UpdateStats()
	})
	cr.Start()

	c.UpdateStats()
	return c
}

// Write sends a batch of samples to Postgres.
func (c *Client) Write(samples model.Samples) error {
	c.UpdateStats()

	txn, err := c.db.Begin()
	if err != nil {
		return err
	}
	defer txn.Rollback()

	lids, err := c.WriteLabels(samples, txn)
	if err != nil {
		return err
	}

	err = c.WriteSamples(samples, txn, lids)
	if err != nil {
		return err
	}

	err = txn.Commit()
	return err
}

func (c *Client) WriteLabels(samples model.Samples, txn *sql.Tx) (map[string]string, error) {
	stmt, err := txn.Prepare(labels_update)
	if err != nil {
		level.Error(c.logger).Log("msg", "cannot prepare label statement", "err", err)
		return nil, err
	}
	defer stmt.Close()

	lids := make(map[string]string)
	for _, s := range samples {
		l := s.Metric.String()
		if _, ok := lids[l]; ok {
			level.Debug(c.logger).Log("msg", "skipping duplicate labels", "labels", l)
			continue
		}

		h := sha1.New()
		h.Write([]byte(l))
		lid := base64.StdEncoding.EncodeToString(h.Sum(nil))
		t := time.Unix(0, s.Timestamp.UnixNano())

		labels, err := json.Marshal(s.Metric)
		if err != nil {
			continue
		}

		ql := string(labels)
		_, err = stmt.Exec(lid, t, ql)
		if err != nil {
			level.Error(c.logger).Log("msg", "error in single label execution", "err", err, "labels", ql, "lid", lid)
			continue
		}

		lids[l] = string(lid)
	}

	return lids, nil
}

func (c *Client) WriteSamples(samples model.Samples, txn *sql.Tx, lids map[string]string) error {
	stmt, err := txn.Prepare(pq.CopyIn("metric_samples", "time", "name", "value", "lid"))
	if err != nil {
		level.Error(c.logger).Log("msg", "cannot prepare sample statement", "err", err)
		return err
	}
	defer stmt.Close()

	for _, s := range samples {
		k, l := c.parseMetric(s.Metric)
		lid, ok := lids[l]
		if !ok {
			level.Error(c.logger).Log("msg", "cannot write sample without labels", "name", k, "labels", l)
			continue
		}

		t := time.Unix(0, s.Timestamp.UnixNano())
		v := float64(s.Value)

		if math.IsNaN(v) || math.IsInf(v, 0) {
			level.Warn(c.logger).Log("msg", "cannot write sample with invalid value", "value", v, "sample", s)
			continue
		}

		level.Debug(c.logger).Log("name", k, "time", t, "value", v, "labels", lid)
		_, err = stmt.Exec(t, k, v, lid)
		if err != nil {
			level.Error(c.logger).Log("msg", "error in single sample execution", "err", err)
			return err
		}
	}

	_, err = stmt.Exec()
	if err != nil {
		level.Error(c.logger).Log("msg", "error in final sample execution", "err", err)
	}

	err = stmt.Close()
	if err != nil {
		level.Error(c.logger).Log("msg", "error closing statement", "err", err)
	}

	return nil
}

// Name identifies the client as a Postgres client.
func (c Client) Name() string {
	return "postgres"
}

func (c Client) parseMetric(m model.Metric) (key string, labels string) {
	return string(m[model.MetricNameLabel]), m.String()
}

func (c Client) UpdateStats() {
	stats := c.db.Stats()
	level.Debug(c.logger).Log("msg", "connection stats", "open", stats.OpenConnections)

	curIdleConns.WithLabelValues(c.Name()).Set(float64(stats.Idle))
	curOpenConns.WithLabelValues(c.Name()).Set(float64(stats.OpenConnections))
	curUsedConns.WithLabelValues(c.Name()).Set(float64(stats.InUse))
	maxOpenConns.WithLabelValues(c.Name()).Set(float64(stats.MaxOpenConnections))
}
