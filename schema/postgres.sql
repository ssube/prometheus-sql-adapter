CREATE TABLE metrics (
  "time" TIMESTAMP NOT NULL,
  "name" TEXT NOT NULL,
  "value" float,
  "labels" jsonb);
SELECT create_hypertable('metrics', 'time',
  partitioning_column => 'name',
  chunk_time_interval => INTERVAL '1 hour',
  migrate_data => 'true');