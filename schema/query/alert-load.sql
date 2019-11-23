SELECT
  REGEXP_REPLACE(instance, '(.+):[0-9]+', '\1') AS "metric",
  "time",
  MAX("load") AS "value"
FROM
(
  SELECT
    metrics.labels->>'instance' AS "instance",
    $__timeGroup("time", $__interval),
    value AS "load"
  FROM metrics
  WHERE
    $__timeFilter("time")
    AND name = 'node_load1'
    AND value != 'NaN'
) t
GROUP BY instance, time
ORDER BY instance, time;