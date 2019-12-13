SELECT
  bucket AS "time",
  metric,
  ((
  CASE 
    WHEN lag(value) OVER w IS NULL THEN 0
    WHEN value > lag(value) OVER w THEN (value - lag(value) OVER w)
    ELSE value
  END
  ) / interval_seconds('$__interval') AS "value"
FROM (
SELECT
  labels->>'pod' AS "metric",
  time_bucket('$__interval', "time") AS "bucket",
  MAX(value) AS "value"
FROM metrics
WHERE
  $__timeFilter("time") and
  name = 'prometheus_remote_storage_succeeded_samples_total'
GROUP BY metric, bucket
ORDER BY metric, bucket
) AS m
WHERE value > 0
WINDOW w AS (PARTITION BY metric ORDER BY bucket)
ORDER BY time;

SELECT
  bucket AS "time",
  metric,
  ((
  CASE 
    WHEN lag(value) OVER w IS NULL THEN 0
    WHEN value > lag(value) OVER w THEN (value - lag(value) OVER w)
    ELSE value
  END
  ) / interval_seconds('$__interval') AS "value"
FROM (
SELECT
  labels->>'pod' AS "metric",
  time_bucket('$__interval', "time") AS "bucket",
  MAX(value) AS "value"
FROM metrics
WHERE
  $__timeFilter("time") and
  name = 'adapter_samples_sent_total'
GROUP BY metric, bucket
ORDER BY metric, bucket
) AS m
WHERE value > 0
WINDOW w AS (PARTITION BY metric ORDER BY bucket)
ORDER BY time;