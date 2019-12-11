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
	"context"
	"database/sql"
	"encoding/binary"
	"encoding/json"
	"errors"
	"math"
	"time"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	lru "github.com/hashicorp/golang-lru"
	"github.com/lib/pq"
	uuid "github.com/nu7hatch/gouuid"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/common/model"
	"github.com/robfig/cron/v3"
)

type ClientConfig struct {
	CacheSize int
	ConnStr   string
	MaxIdle   int
	MaxOpen   int
	PingCron  string
}

// Client allows sending batches of Prometheus samples to Postgres.
type Client struct {
	logger log.Logger

	cache *lru.Cache
	cron  *cron.Cron
	db    *sql.DB
}

type Metrics []*model.Metric

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
	pingTime = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:      "ping_seconds",
			Namespace: "adapter",
			Subsystem: "connections",
		},
		[]string{"remote"},
	)
	labelCacheSize = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name:      "cache_current",
			Namespace: "adapter",
			Subsystem: "labels",
			Help:      "Current number of cached label sets.",
		},
		[]string{"remote"},
	)
	totalSkippedLabels = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "skipped_total",
			Namespace: "adapter",
			Subsystem: "labels",
		},
		[]string{"remote"},
	)
	totalWrittenLabels = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "written_total",
			Namespace: "adapter",
			Subsystem: "labels",
		},
		[]string{"remote"},
	)
	totalInvalidSamples = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "invalid_total",
			Namespace: "adapter",
			Subsystem: "samples",
		},
		[]string{"remote"},
	)
	totalWrittenSamples = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "written_total",
			Namespace: "adapter",
			Subsystem: "samples",
		},
		[]string{"remote"},
	)

	labelsNothing = "INSERT INTO metric_labels(lid, time, labels) VALUES ( $1, $2, $3 ) ON CONFLICT (lid) DO NOTHING"
	labelsUpdate  = "INSERT INTO metric_labels(lid, time, labels) VALUES ( $1, $2, $3 ) ON CONFLICT (lid) DO UPDATE SET time = EXCLUDED.time"
)

func init() {
	prometheus.MustRegister(curIdleConns)
	prometheus.MustRegister(curUsedConns)
	prometheus.MustRegister(curOpenConns)
	prometheus.MustRegister(maxOpenConns)
	prometheus.MustRegister(labelCacheSize)
	prometheus.MustRegister(pingTime)
	prometheus.MustRegister(totalSkippedLabels)
	prometheus.MustRegister(totalWrittenLabels)
	prometheus.MustRegister(totalInvalidSamples)
	prometheus.MustRegister(totalWrittenSamples)
}

// NewClient creates a new Client.
func NewClient(logger log.Logger, config ClientConfig) *Client {
	if logger == nil {
		logger = log.NewNopLogger()
	}

	level.Info(logger).Log("msg", "connecting to database", "idle", config.MaxIdle, "open", config.MaxOpen)
	db, err := sql.Open("postgres", config.ConnStr)
	if err != nil {
		level.Error(logger).Log("msg", "error opening database connection", "err", err)
		return nil
	}

	db.SetMaxIdleConns(config.MaxIdle)
	db.SetMaxOpenConns(config.MaxOpen)

	level.Info(logger).Log("msg", "creating cache", "size", config.CacheSize)
	cache, err := lru.New(config.CacheSize)
	if err != nil {
		level.Error(logger).Log("msg", "error creating lid cache", "err", err)
		return nil
	}

	c := &Client{
		cache:  cache,
		cron:   cron.New(cron.WithSeconds()),
		logger: logger,
		db:     db,
	}

	c.cron.AddFunc(config.PingCron, func() {
		c.UpdateStats()
	})
	c.cron.Start()

	c.UpdateStats()
	return c
}

func (c *Client) PrepareStmt(rawStmt string) (*sql.Tx, *sql.Stmt, error) {
	txn, err := c.db.Begin()
	if err != nil {
		level.Error(c.logger).Log("msg", "error writing samples", "err", err)
		return nil, nil, err
	}

	stmt, err := txn.Prepare(rawStmt)
	if err != nil {
		level.Error(c.logger).Log("msg", "cannot prepare sample statement", "err", err)
		return nil, nil, err
	}

	return txn, stmt, nil
}

// Write sends a batch of samples to Postgres.
func (c *Client) Write(metrics Metrics, samples model.Samples) error {
	err := c.WriteLabels(metrics)
	if err != nil {
		level.Error(c.logger).Log("msg", "error beginning transaction", "err", err)
		return err
	}

	err = c.WriteSamples(samples)
	if err != nil {
		level.Error(c.logger).Log("msg", "error writing labels", "err", err)
		return err
	}

	return nil
}

func (c *Client) WriteLabels(metrics Metrics) error {
	txn, stmt, err := c.PrepareStmt(labelsUpdate)
	if err != nil {
		level.Error(c.logger).Log("msg", "cannot prepare label statement", "err", err)
		return err
	}

	defer stmt.Close()
	defer txn.Rollback()

	writtenLabels := 0
	skippedLabels := 0
	t := time.Now()

	for _, m := range metrics {
		written, skipped, err := c.WriteLabel(m, stmt, t)
		if err != nil {
			level.Error(c.logger).Log("msg", "error writing single label", "err", err)
			return err
		}

		writtenLabels += written
		skippedLabels += skipped
	}

	err = stmt.Close()
	if err != nil {
		level.Error(c.logger).Log("msg", "error closing label statement", "err", err)
	}

	err = txn.Commit()
	if err != nil {
		level.Error(c.logger).Log("msg", "error committing labels", "err", err)
		return err
	}

	totalSkippedLabels.WithLabelValues(c.Name()).Add(float64(skippedLabels))
	totalWrittenLabels.WithLabelValues(c.Name()).Add(float64(writtenLabels))

	return nil
}

func (c *Client) WriteLabel(m *model.Metric, stmt *sql.Stmt, t time.Time) (written int, skipped int, err error) {
	lid, err := c.makeLid(m)
	if err != nil {
		level.Warn(c.logger).Log("msg", "error hashing labels", "err", err)
		return 0, 0, err
	}

	if c.cache.Contains(lid) {
		level.Debug(c.logger).Log("msg", "skipping duplicate labels", "lid", lid)
		return 0, 1, err
	}

	labels, err := c.marshalMetric(m)
	if err != nil {
		level.Warn(c.logger).Log("msg", "error marshaling metric", "err", err, "lid", lid)
		return 0, 0, err
	}

	_, err = stmt.Exec(lid, t, labels)
	if err != nil {
		level.Warn(c.logger).Log("msg", "error in single label execution", "err", err, "labels", labels, "lid", lid)
		return 0, 0, err
	}

	c.cache.Add(lid, nil)
	return 1, 0, nil
}

func (c *Client) WriteSamples(samples model.Samples) error {
	txn, stmt, err := c.PrepareStmt(pq.CopyIn("metric_samples", "time", "name", "value", "lid"))
	if err != nil {
		level.Error(c.logger).Log("msg", "error preparing sample statement", "err", err)
		return err
	}

	defer stmt.Close()
	defer txn.Rollback()

	invalidSamples := 0
	writtenSamples := 0

	for _, s := range samples {
		written, invalid, err := c.WriteSample(s, txn, stmt)
		if err != nil {
			level.Error(c.logger).Log("msg", "error writing single sample", "err", err)
			return err
		}

		invalidSamples += invalid
		writtenSamples += written
	}

	_, err = stmt.Exec()
	if err != nil {
		level.Error(c.logger).Log("msg", "error in final sample execution", "err", err)
	}

	err = stmt.Close()
	if err != nil {
		level.Error(c.logger).Log("msg", "error closing sample statement", "err", err)
	}

	err = txn.Commit()
	if err != nil {
		level.Error(c.logger).Log("msg", "error committing samples", "err", err)
		return err
	}

	totalInvalidSamples.WithLabelValues(c.Name()).Add(float64(invalidSamples))
	totalWrittenSamples.WithLabelValues(c.Name()).Add(float64(writtenSamples))

	return nil
}

func (c *Client) WriteSample(s *model.Sample, txn *sql.Tx, stmt *sql.Stmt) (written int, invalid int, err error) {
	lid, name, err := c.parseMetric(s.Metric)
	if err != nil {
		level.Warn(c.logger).Log("msg", "cannot parse metric", "err", err)
		return 0, 0, nil
	}

	ok := c.cache.Contains(lid)
	if !ok {
		level.Warn(c.logger).Log("msg", "cannot write sample without labels", "name", name, "lid", lid)
		err = errors.New("cannot write sample without labels")
		return 0, 0, nil
	}

	t := time.Unix(0, s.Timestamp.UnixNano())
	v := float64(s.Value)

	if math.IsNaN(v) || math.IsInf(v, 0) {
		level.Warn(c.logger).Log("msg", "cannot write sample with invalid value", "value", v, "sample", s)
		return 0, 1, nil
	}

	level.Debug(c.logger).Log("name", name, "time", t, "value", v, "labels", lid)
	_, err = stmt.Exec(t, name, v, lid)
	if err != nil {
		level.Error(c.logger).Log("msg", "error in single sample execution", "err", err)
		// this is the only error case that is actually fatal for the transaction and must return err
		return 0, 0, err
	}

	return 1, 0, nil
}

// Name identifies the client as a Postgres client.
func (c Client) Name() string {
	return "postgres"
}

func (c Client) makeLid(m *model.Metric) (string, error) {
	buf := make([]byte, 16)
	binary.LittleEndian.PutUint64(buf[0:], 0)
	binary.LittleEndian.PutUint64(buf[8:], uint64(m.Fingerprint()))

	u, err := uuid.Parse(buf)
	if err != nil {
		return "", err
	}

	return u.String(), nil
}

func (c Client) marshalMetric(m *model.Metric) (string, error) {
	buf, err := json.Marshal(m)
	if err != nil {
		return "", err
	}
	return string(buf), nil
}

func (c Client) parseMetric(m model.Metric) (string, string, error) {
	lid, err := c.makeLid(&m)
	if err != nil {
		return "", "", err
	}
	return lid, string(m[model.MetricNameLabel]), nil
}

func (c Client) UpdateStats() {
	cname := c.Name()
	stats := c.db.Stats()
	level.Debug(c.logger).Log("msg", "connection stats", "open", stats.OpenConnections)

	curIdleConns.WithLabelValues(cname).Set(float64(stats.Idle))
	curOpenConns.WithLabelValues(cname).Set(float64(stats.OpenConnections))
	curUsedConns.WithLabelValues(cname).Set(float64(stats.InUse))
	maxOpenConns.WithLabelValues(cname).Set(float64(stats.MaxOpenConnections))
	labelCacheSize.WithLabelValues(cname).Set(float64(c.cache.Len()))

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	begin := time.Now()
	err := c.db.PingContext(ctx)
	duration := time.Since(begin).Seconds()
	if err != nil {
		level.Error(c.logger).Log("msg", "error pinging server", "err", err)
	}

	pingTime.WithLabelValues(cname).Observe(duration)
}
