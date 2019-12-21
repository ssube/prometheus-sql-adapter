package main

import (
	"testing"

	"github.com/go-kit/kit/log"
	"github.com/prometheus/common/model"
	"github.com/ssube/prometheus-sql-adapter/metric"
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
