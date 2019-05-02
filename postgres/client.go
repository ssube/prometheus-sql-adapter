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
	"database/sql"
	"encoding/json"
	"math"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/lib/pq"
	"github.com/prometheus/common/model"
)

// Client allows sending batches of Prometheus samples to Postgres.
type Client struct {
	logger log.Logger

	db *sql.DB
}

// NewClient creates a new Client.
func NewClient(logger log.Logger, conn string, idle int, open int) *Client {
	if logger == nil {
		logger = log.NewNopLogger()
	}
	db, err := sql.Open("postgres", conn)
	if err != nil {
		level.Error(logger).Log(err)
	}
	db.SetMaxIdleConns(idle)
	db.SetMaxOpenConns(open)
	return &Client{
		logger:    logger,
		db:        db,
	}
}

// Write sends a batch of samples to Postgres.
func (c *Client) Write(samples model.Samples) error {
	txn, err := c.db.Begin()
	if err != nil {
		return err
	}

	stmt, err := txn.Prepare(pq.CopyIn("metrics", "name", "time", "value", "labels"))
	if err != nil {
		level.Error(c.logger).Log("msg", "cannot prepare copy statement", "err", err)
		return err
	}

	for _, s := range samples {
		k, l := c.parseMetric(s.Metric)
		t := float64(s.Timestamp.UnixNano()) / 1e9
		v := float64(s.Value)

		if math.IsNaN(v) || math.IsInf(v, 0) {
			level.Debug(c.logger).Log("msg", "cannot send value to Postgres, skipping sample", "value", v, "sample", s)
			continue
		}

		level.Debug(c.logger).Log("name", k, "time", t, "value", v, "labels", string(l))
		_, err = stmt.Exec(k, t, v, l)
		if err != nil {
			level.Error(c.logger).Log("msg", "error in sample execution", "err", err)
			return err
		}
	}

	_,err = stmt.Exec()
	if err != nil {
		level.Error(c.logger).Log("msg", "error in final execution", "err", err)
	}

	err = stmt.Close()
	if err != nil {
		level.Error(c.logger).Log("msg", "error closing statement", "err", err)
	}

	err = txn.Commit()
	return err
}

// Name identifies the client as a Postgres client.
func (c Client) Name() string {
	return "postgres"
}

func (c Client) parseMetric(m model.Metric) (key string, labels []byte) {
	labelBuf, err := json.Marshal(m)

	if err != nil {
		level.Error(c.logger).Log("msg", "error marshalling metric labels", "err", err)
	}

	return string(m[model.MetricNameLabel]), labelBuf
}