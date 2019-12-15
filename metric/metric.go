package metric

import (
	"encoding/binary"
	"encoding/json"
	"strings"

	uuid "github.com/nu7hatch/gouuid"
	"github.com/prometheus/common/model"
)

// Batch of metrics
type Metrics []*model.Metric

// FilterMetric based on name label and list of allowed name prefixes
func FilterMetric(m *model.Metric, allowedNames []string) bool {
	n := GetName(m)
	for _, n := range allowed {
		if strings.HasPrefix(name, n) {
			return true
		}
	}

	return false
}

// GetName label from a metric
func GetName(m *model.Metric) string {
	return m[model.MetricNameLabel]
}

// MakeLid extracts the lid hash from a metric
func MakeLid(m *model.Metric) (string, error) {
	buf := make([]byte, 16)
	binary.LittleEndian.PutUint64(buf[0:], 0)
	binary.LittleEndian.PutUint64(buf[8:], uint64(m.Fingerprint()))

	u, err := uuid.Parse(buf)
	if err != nil {
		return "", err
	}

	return u.String(), nil
}

// MakeLidName extracts both the lid hash and name label from a metric
func MakeLidName(m model.Metric) (string, string, error) {
	lid, err := MakeLid(&m)
	if err != nil {
		return "", "", err
	}
	return lid, GetName(m), nil
}

// MarshalMetric to JSON
func MarshalMetric(m *model.Metric) (string, error) {
	buf, err := json.Marshal(m)
	if err != nil {
		return "", err
	}
	return string(buf), nil
}
