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
		t.Error("test_ metric should be allowed")
	}
}

func TestFilterMetricBlocked(t *testing.T) {
	m := []model.Metric{
		model.Metric{},
		model.Metric{},
	}
	m[0][model.MetricNameLabel] = "allow_foo"
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

func TestMakeLid(t *testing.T) {
	m := model.Metric{}
	m[model.MetricNameLabel] = "test_foo"
	m["job"] = "test_bar"

	lid, err := MakeLid(&m)
	if err != nil {
		t.Fail()
	}

	testLID := "00000000-0000-0000-b4d5-db0b9ba93f3a"
	if lid != testLID {
		t.Errorf("lid should be '%s', got '%s'", testLID, lid)
	}
}

func TestMakeLidNil(t *testing.T) {
	lid, err := MakeLid(nil)
	if lid != "" {
		t.Fail()
	}
	if err == nil {
		t.Fail()
	}
}

func TestMakeLidName(t *testing.T) {
	testName := "test_foo"

	m := model.Metric{}
	m[model.MetricNameLabel] = model.LabelValue(testName)

	lid, name, err := MakeLidName(m)
	if err != nil {
		t.Error(err)
	}

	testLID := "00000000-0000-0000-dda7-a6f37ea71bf2"
	if lid != testLID {
		t.Errorf("lid should be '%s', got '%s'", testLID, lid)
	}

	if name != testName {
		t.Errorf("name should be '%s', got '%s'", testName, name)
	}
}

func TestMarshalMetric(t *testing.T) {
	m := model.Metric{}
	m[model.MetricNameLabel] = "test_foo"
	m["job"] = "test_bar"

	json, err := MarshalMetric(&m)
	if err != nil {
		t.Error(err)
	}

	testJSON := `{"__name__":"test_foo","job":"test_bar"}`
	if json != testJSON {
		t.Errorf("marshalled metric should be '%s', got '%s'", testJSON, json)
	}
}
