CREATE VIEW agg_instance_load
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '5m',
  timescaledb.refresh_lag = '5m'
) AS SELECT
  lid,
  time_bucket('5 minutes', time) "bucket",
  AVG(value) AS "avg_load",
  MAX(value) AS "max_load"
FROM metric_samples
WHERE
  name = 'node_load1'
GROUP BY lid, bucket;


CREATE VIEW agg_instance_load_long
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '1h',
  timescaledb.refresh_lag = '1h'
) AS SELECT
  lid,
  time_bucket('1 hour', time) AS "bucket",
  AVG(value) AS "avg_load",
  MAX(value) AS "max_load"
FROM metric_samples
WHERE
  name = 'node_load1'
GROUP BY lid, bucket;
