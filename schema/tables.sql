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

CREATE INDEX IF NOT EXISTS metric_labels_instance_lid ON metric_labels ((labels->>'instance'), lid);
CREATE INDEX IF NOT EXISTS metric_labels_name_lid ON metric_labels ((labels->>'__name__'), lid);
CREATE INDEX IF NOT EXISTS metric_labels_name_namespace_podname ON metric_labels
  USING BTREE ((labels->>'__name__'), (labels->>'namespace'), (labels->>'pod_name'))
  WHERE labels ?& array['namespace', 'pod_name'];

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

CREATE INDEX IF NOT EXISTS metric_samples_lid_time ON metric_samples USING BTREE (lid, time DESC);
-- this index is required for caggs, but causes 2x write amplification
CREATE INDEX IF NOT EXISTS metric_samples_name_time ON metric_samples USING BTREE (name, time DESC);

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
  l.labels->>'__name__' AS name,
  s.lid,
  s.value,
  l.labels
FROM metric_labels AS l
JOIN metric_samples AS s
  ON s.lid = l.lid
WHERE
  s.time > NOW() - INTERVAL :retain_live;  -- prevent high-resolution queries from searching compressed chunks
