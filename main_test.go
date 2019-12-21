package main

import (
	"testing"

	"github.com/go-kit/kit/log"
	"github.com/prometheus/common/model"
	"github.com/ssube/prometheus-sql-adapter/metric"
	"github.com/ssube/prometheus-sql-adapter/postgres"
)

type MockWriter struct {
	MetricCount int
	SampleCount int
}

func CreateMockWriter() *MockWriter {
	w := MockWriter{
		MetricCount: 0,
		SampleCount: 0,
	}

	return &w
}

func (w *MockWriter) Write(metrics metric.Metrics, samples model.Samples) error {
	w.MetricCount += len(metrics)
	w.SampleCount += len(samples)

	return nil
}

func (w *MockWriter) Name() string {
	return "MockWriter"
}

func TestSendSamples(t *testing.T) {
	log := log.NewNopLogger()
	w := CreateMockWriter()
	metrics := metric.Metrics{
		&model.Metric{},
		&model.Metric{},
	}
	samples := model.Samples{}

	sendSamples(log, w, metrics, samples)

	if w.MetricCount != 2 {
		t.Errorf("expected %d metrics, got %d", 2, w.MetricCount)
	}

	if w.SampleCount != 0 {
		t.Errorf("expected %d samples, got %d", 0, w.SampleCount)
	}
}

func TestParseCacheFlags(t *testing.T) {
	args := []string{
		"prometheus-sql-adapter",
		"--pg.cache-size=4",
	}
	cfg := parseFlags(args)

	if cfg == nil {
		t.FailNow()
	}

	testSize := 4
	if cfg.Postgres.CacheSize != testSize {
		t.Errorf("expected postgres cache size to be %d, got %d", testSize, cfg.Postgres.CacheSize)
	}
}

func TestParseConnFlags(t *testing.T) {
	args := []string{
		"prometheus-sql-adapter",
		"--pg.max-idle=4",
		"--pg.max-open=8",
	}
	cfg := parseFlags(args)

	if cfg == nil {
		t.FailNow()
	}

	testIdle := 4
	if cfg.Postgres.MaxIdle != testIdle {
		t.Errorf("expected idle conn limit to be %d, got %d", testIdle, cfg.Postgres.MaxIdle)
	}

	testOpen := 8
	if cfg.Postgres.MaxOpen != testOpen {
		t.Errorf("expected open conn limit to be %d, got %d", testOpen, cfg.Postgres.MaxOpen)
	}
}

func TestParseFlagsError(t *testing.T) {
	args := []string{
		"some-exec",
		"--no",
		"--foop",
	}
	cfg := parseFlags(args)

	if cfg != nil {
		t.Error("args were not expected to parse")
	}
}

func TestBuildClientsEmpty(t *testing.T) {
	log := log.NewNopLogger()
	cfg := config{
		Postgres: postgres.ClientConfig{
			ConnStr: "",
		},
	}

	readers, writers := buildClients(log, &cfg)

	if len(readers) > 0 {
		t.Errorf("expected 0 readers, got %d", len(readers))
	}

	if len(writers) > 0 {
		t.Errorf("expected 0 writers, got %d", len(writers))
	}
}
