package metric

import (
	"testing"

	"github.com/prometheus/common/model"
)

func TestFilterMetricAllowed(t *testing.T) {
	m := model.Metric{}
	m[model.MetricNameLabel] = "test_foo"
	names := []string{
		"test_",
	}

	allowed := FilterMetric(&m, names)
	if allowed != true {
		t.Fail()
	}
}

func TestFilterMetricBlocked(t *testing.T) {
	m := make([]model.Metric, 2)
	m[0] = model.Metric{}
	m[0][model.MetricNameLabel] = "allow_foo"
	m[1] = model.Metric{}
	m[1][model.MetricNameLabel] = "block_bar"
	names := []string{
		"allow_",
	}

	allowed := FilterMetric(&m[1], names)
	if allowed {
		t.Fail()
	}
}

func TestFilterMetricNil(t *testing.T) {
	names := []string{
		"test_",
	}
	allowed := FilterMetric(nil, names)
	if allowed {
		t.Fail()
	}
}

func TestGetName(t *testing.T) {
	testName := "test_foo"
	m := model.Metric{}
	m[model.MetricNameLabel] = model.LabelValue(testName)

	name := GetName(m)
	if name != testName {
		t.Fail()
	}
}
