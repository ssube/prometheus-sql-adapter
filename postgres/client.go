package postgres

import (
	"context"
	"database/sql"
	"math"
	"time"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	lru "github.com/hashicorp/golang-lru"
	"github.com/lib/pq"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/common/model"
	"github.com/robfig/cron/v3"
	"github.com/ssube/prometheus-sql-adapter/metric"
)

// ClientConfig for Postgres Client
type ClientConfig struct {
	CacheSize   int
	ConnStr     string
	MaxIdle     int
	MaxOpen     int
	PingCron    string
	TxIsolation string
}

// Client allows sending batches of Prometheus samples to Postgres.
type Client struct {
	config ClientConfig
	logger log.Logger

	cache     *lru.Cache
	cron      *cron.Cron
	db        *sql.DB
	isolation sql.IsolationLevel
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
		cache:     cache,
		config:    config,
		cron:      cron.New(cron.WithSeconds()),
		db:        db,
		isolation: ParseIsolationLevel(config.TxIsolation),
		logger:    logger,
	}

	c.cron.AddFunc(config.PingCron, func() {
		c.UpdateStats()
	})
	c.cron.Start()

	c.UpdateStats()
	return c
}

// Name identifies the client as a Postgres client.
func (c Client) Name() string {
	return "postgres"
}

// PrepareStmt within a transaction using the configured isolation level
func (c *Client) PrepareStmt(rawStmt string) (*sql.Tx, *sql.Stmt, error) {
	txn, err := c.db.BeginTx(context.Background(), &sql.TxOptions{
		Isolation: c.isolation,
	})
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

// UpdateStats pings the server and updates connection metrics
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

// Write sends a batch of samples to Postgres.
func (c *Client) Write(metrics metric.Metrics, samples model.Samples) error {
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

// WriteLabels from a batch write
func (c *Client) WriteLabels(metrics metric.Metrics) error {
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
		written, err := c.WriteLabel(m, stmt, t)
		if err != nil {
			level.Error(c.logger).Log("msg", "error writing single label", "err", err)
			return err
		}

		if written {
			writtenLabels++
		} else {
			skippedLabels++
		}
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

// WriteLabel using a prepared statement and last seen time
func (c *Client) WriteLabel(m *model.Metric, stmt *sql.Stmt, t time.Time) (written bool, err error) {
	lid, err := metric.MakeLid(m)
	if err != nil {
		level.Warn(c.logger).Log("msg", "error hashing labels", "err", err)
		return false, err
	}

	if c.cache.Contains(lid) {
		level.Debug(c.logger).Log("msg", "skipping duplicate labels", "lid", lid)
		return false, nil
	}

	labels, err := metric.MarshalMetric(m)
	if err != nil {
		level.Warn(c.logger).Log("msg", "error marshaling metric", "err", err, "lid", lid)
		return false, err
	}

	_, err = stmt.Exec(lid, t, labels)
	if err != nil {
		level.Warn(c.logger).Log("msg", "error in single label execution", "err", err, "labels", labels, "lid", lid)
		return false, err
	}

	c.cache.Add(lid, nil)
	return true, nil
}

// WriteSamples from a batch write
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
		written, err := c.WriteSample(s, txn, stmt)
		if err != nil {
			level.Error(c.logger).Log("msg", "error writing single sample", "err", err)
			return err
		}

		if written {
			writtenSamples++
		} else {
			invalidSamples++
		}
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

// WriteSample using a prepared statement
func (c *Client) WriteSample(s *model.Sample, txn *sql.Tx, stmt *sql.Stmt) (written bool, err error) {
	lid, name, err := metric.MakeLidName(s.Metric)
	if err != nil {
		level.Warn(c.logger).Log("msg", "cannot parse metric", "err", err)
		return false, err
	}

	t := time.Unix(0, s.Timestamp.UnixNano())
	v := float64(s.Value)

	if math.IsNaN(v) || math.IsInf(v, 0) {
		level.Warn(c.logger).Log("msg", "cannot write sample with invalid value", "value", v, "sample", s)
		return false, nil
	}

	level.Debug(c.logger).Log("name", name, "time", t, "value", v, "labels", lid)
	_, err = stmt.Exec(t, name, v, lid)
	if err != nil {
		level.Error(c.logger).Log("msg", "error in single sample execution", "err", err)
		// this is the only error case that is actually fatal for the transaction and must return err
		return false, err
	}

	return true, nil
}

// ParseIsolationLevel converts a string level back to int
func ParseIsolationLevel(level string) sql.IsolationLevel {
	switch level {
	case "Read Uncommitted":
		return sql.LevelReadUncommitted
	case "Read Committed":
		return sql.LevelReadCommitted
	case "Write Committed":
		return sql.LevelWriteCommitted
	case "Repeatable Read":
		return sql.LevelRepeatableRead
	case "Snapshot":
		return sql.LevelSnapshot
	case "Serializable":
		return sql.LevelSerializable
	case "Linearizable":
		return sql.LevelLinearizable
	case "Default":
		fallthrough
	default:
		return sql.LevelDefault
	}
}
