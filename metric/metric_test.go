package metric

import (
	"testing"

	"github.com/prometheus/common/model"
)

func TestFilterMetric(t *testing.T) {
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
