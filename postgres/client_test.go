package postgres

import (
	"database/sql"
	"testing"
)

func TestInvalidConn(t *testing.T) {
	config := ClientConfig{}
	client := NewClient(nil, config)

	if client != nil {
		t.Error("client should not be created")
	}
}

func TestParseIsolationLevel(t *testing.T) {
	levels := map[string]sql.IsolationLevel{
		"Read Uncommitted": sql.LevelReadUncommitted,
		"Read Committed":   sql.LevelReadCommitted,
		"Write Committed":  sql.LevelWriteCommitted,
		"Repeatable Read":  sql.LevelRepeatableRead,
		"Snapshot":         sql.LevelSnapshot,
		"Serializable":     sql.LevelSerializable,
		"Linearizable":     sql.LevelLinearizable,
		"Default":          sql.LevelDefault,
		"foo":              sql.LevelDefault,
		"test":             sql.LevelDefault,
	}

	for name, level := range levels {
		parsed := ParseIsolationLevel(name)
		if parsed != level {
			t.Errorf("expected parsed level to be %d, got %d", level, parsed)
		}
	}
}
