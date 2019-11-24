ALTER TABLE metric_samples
SET (
  timescaledb.compress,
  timescaledb.compress_orderby = 'time DESC',
  timescaledb.compress_segmentby = 'lid'
);

SELECT add_compress_chunks_policy(
  'metric_samples',
  INTERVAL '6 hours'
);