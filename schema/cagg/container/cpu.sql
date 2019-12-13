CREATE VIEW agg_container_cpu
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '15m',
  timescaledb.refresh_lag = '15m')
AS SELECT
  lid,
  time_bucket('15 minutes', time) AS "bucket",
  (MAX(value) - MIN(value)) / interval_seconds('15 minutes') AS delta_usage
FROM metric_samples
WHERE 
  name = 'container_cpu_usage_seconds_total'
GROUP BY lid, bucket;
