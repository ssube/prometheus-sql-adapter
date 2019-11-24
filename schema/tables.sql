-- labels
CREATE TABLE IF NOT EXISTS metric_labels (
  "lid" TEXT NOT NULL,          -- label ID: SHA1 of sample.Metric.String()
  "time" TIMESTAMP NOT NULL,    -- last seen time: latest sample time
  "labels" jsonb                -- label contents
);

CREATE UNIQUE INDEX metric_labels_lid ON metric_labels (lid);
CREATE INDEX metric_labels_labels ON metric_labels USING GIN (labels);

-- samples
CREATE TABLE IF NOT EXISTS metric_samples (
  "time" TIMESTAMP NOT NULL,    -- sample time
  "name" TEXT NOT NULL,         -- metric name
  "lid" TEXT NOT NULL,          -- metric lid
  "value" float                 -- value
);

SELECT create_hypertable(
  'metric_samples',
  'time',
  partitioning_column => 'name',
  chunk_time_interval => INTERVAL '1 hour',
  create_default_indexes => TRUE,
  if_not_exists => TRUE,
  migrate_data => TRUE
);

SELECT set_chunk_time_interval('metric_samples', INTERVAL '1 hour');

CREATE OR REPLACE VIEW metrics AS
SELECT
  s.time,
  s.name,
  s.lid,
  s.value,
  l.labels
FROM metric_samples AS s
JOIN metric_labels AS l ON s.lid = l.lid
WHERE s.time > NOW() - INTERVAL '3 hours';  -- maximum time range for high-resolution queries