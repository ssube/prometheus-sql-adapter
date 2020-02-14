CREATE VIEW agg_pod_count
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '60m',
  timescaledb.refresh_lag = '60m')
AS SELECT
  lid,
  time_bucket('60 minutes', time) AS "bucket",
  MIN(value) AS min_pods,
  AVG(value) AS avg_pods,
  MAX(value) AS max_pods
FROM metric_samples
WHERE
  name = 'kube_deployment_status_replicas_available'
GROUP BY lid, bucket;