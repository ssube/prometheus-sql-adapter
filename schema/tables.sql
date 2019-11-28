-- extensions
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- labels
CREATE TABLE IF NOT EXISTS metric_labels (
  "lid"     uuid NOT NULL,                -- label ID: fingerprint hash of metric name+labels
  "time"    TIMESTAMP NOT NULL,           -- last seen time: latest sample time
  "labels"  jsonb NOT NULL                -- label contents
);

CREATE UNIQUE INDEX IF NOT EXISTS metric_labels_lid ON metric_labels (lid);
CREATE INDEX IF NOT EXISTS metric_labels_labels ON metric_labels USING GIN (labels);

-- samples
CREATE TABLE IF NOT EXISTS metric_samples (
  "time"  TIMESTAMP NOT NULL,             -- sample time
  "name"  TEXT NOT NULL,                  -- metric name
  "lid"   uuid NOT NULL,                  -- metric lid
  "value" double precision NOT NULL       -- value
);

SELECT create_hypertable(
  'metric_samples',
  'time',
  chunk_time_interval => INTERVAL '1 hour',
  create_default_indexes => TRUE,
  if_not_exists => TRUE,
  migrate_data => TRUE
);

SELECT set_chunk_time_interval('metric_samples', INTERVAL '1 hour');

CREATE INDEX IF NOT EXISTS metric_samples_name_lid_time ON metric_samples USING BTREE (name, lid, time DESC);

-- samples compression
ALTER TABLE metric_samples
SET (
  timescaledb.compress,
  timescaledb.compress_orderby = 'time DESC',
  timescaledb.compress_segmentby = 'lid'
);

SELECT add_compress_chunks_policy(
  'metric_samples',
  INTERVAL :retain_live
);

CREATE OR REPLACE VIEW metrics AS
SELECT
  s.time,
  s.name,
  s.lid,
  s.value,
  l.labels
FROM metric_samples AS s
JOIN metric_labels AS l ON s.lid = l.lid
WHERE s.time > NOW() - INTERVAL :retain_live;  -- maximum time range for high-resolution queries
