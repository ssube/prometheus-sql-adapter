SELECT
  coalesce(MAX(apps), 'unknown') AS "metric",
  time,
  MIN(current) AS "value"
FROM
(
  SELECT
    CONCAT(labels->>'exported_namespace', '/', labels->>'deployment') AS "apps",
    "time",
    value AS "current"
  FROM metrics
  WHERE
    $__timeFilter("time") and
    name = 'kube_deployment_status_replicas_available' and
    value != 'NaN'
) t
GROUP BY apps, time
ORDER BY apps, time;