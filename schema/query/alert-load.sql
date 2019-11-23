SELECT
  coalesce(MAX(nodename), MAX(instance), 'unknown') AS "metric",
  "time",
  MAX("load") AS "value"
FROM
(
  SELECT
    metrics.labels->>'instance' AS "instance",
    $__timeGroup("time", $__interval),
    CASE WHEN name = 'node_uname_info' THEN labels->>'nodename' ELSE NULL END AS "nodename",
    CASE WHEN name = 'node_load1' THEN value ELSE NULL END AS "load"
  FROM metrics
  WHERE
    $__timeFilter("time")
    AND name IN ('node_uname_info', 'node_load1')
    AND value != 'NaN'
) t
GROUP BY instance, time
ORDER BY instance, time;