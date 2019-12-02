-- set up a drop_chunks policy
-- this requires a timescale cloud or enterprise license

SELECT add_drop_chunks_policy(
  hypertable => 'metric_samples',
  older_than => INTERVAL :retain_total,
  cascade_to_materializations => TRUE,
  if_not_exists => TRUE
);
