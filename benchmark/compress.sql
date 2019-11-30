SELECT set_chunk_time_interval('metrics_values', INTERVAL '1 hour');

ALTER TABLE metrics_values SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'labels_id'
);

SELECT add_compress_chunks_policy('metrics_values', INTERVAL '6 hours');