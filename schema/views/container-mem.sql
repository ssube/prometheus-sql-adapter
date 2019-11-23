CREATE VIEW agg_container_mem
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '15m',
  timescaledb.refresh_lag = '15m')
AS SELECT
  lid,
  time_bucket('15 minutes', time) AS "bucket",
  MAX(value) AS max_rss,
  AVG(value) AS avg_rss,
  MIN(value) AS min_rss
FROM metric_samples
WHERE 
  name = 'container_memory_rss'
GROUP BY lid, bucket;
