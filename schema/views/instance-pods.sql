CREATE VIEW agg_instance_pods
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '5m',
  timescaledb.refresh_lag = '5m')
AS SELECT
  lid,
  time_bucket('5 minutes', time) AS "bucket",
  MAX(value) AS "pods"
FROM metric_samples
WHERE
  name = 'kubelet_running_pod_count'
GROUP BY lid, bucket;
