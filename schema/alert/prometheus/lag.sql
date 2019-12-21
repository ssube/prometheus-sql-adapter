SELECT
  metrics.labels->>'pod' AS "metric",
  MAX("time") AS "time",
  EXTRACT(EPOCH FROM NOW()) - MAX(value) AS "value"
FROM metrics
WHERE
  time > NOW() - INTERVAL '15 minute' AND
  name = 'prometheus_remote_storage_highest_timestamp_in_seconds' AND
  value != 'NaN'
GROUP BY metric
ORDER BY time DESC
LIMIT 4;


SELECT
  MAX(pod) AS "metric",
  "time",
  MAX("local") - MAX("remote") AS "value"
FROM (
  SELECT
    metrics.labels->>'pod' AS "pod",
    $__timeGroup("time", ${__interval}),
    CASE WHEN name = 'prometheus_remote_storage_highest_timestamp_in_seconds' THEN value ELSE NULL END AS "local",
    CASE WHEN name = 'prometheus_remote_storage_queue_highest_sent_timestamp_seconds' THEN value ELSE NULL END AS "remote"
  FROM metrics
  WHERE
    $__timeFilter("time")
    AND name IN ('prometheus_remote_storage_highest_timestamp_in_seconds', 'prometheus_remote_storage_queue_highest_sent_timestamp_seconds')
    AND value != 'NaN'
) AS t
GROUP BY time, pod
ORDER BY time, pod;