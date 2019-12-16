CREATE VIEW agg_grafana_alert
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '1h',
  timescaledb.refresh_lag = '1h'
) AS SELECT
  lid,
  time_bucket('1 hour', time) AS "bucket",
  rate(MAX(value), MIN(value)) AS delta_value,
  MAX(value) AS max_value
FROM metric_samples
WHERE
  name = 'grafana_alerting_result_total'
GROUP BY lid, bucket;

CREATE VIEW agg_grafana_alert_long
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '1h',
  timescaledb.refresh_lag = '1h'
) AS SELECT
  lid,
  time_bucket('1 day', time) AS "bucket",
  rate(MAX(value), MIN(value)) AS delta_value,
  MAX(value) AS max_value
FROM metric_samples
WHERE
  name = 'grafana_alerting_result_total'
GROUP BY lid, bucket;

