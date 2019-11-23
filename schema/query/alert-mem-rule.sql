SELECT
  REGEXP_REPLACE(metrics.labels->>'instance', '(.+):[0-9]+', '\1') AS "instance",
  $__timeGroup("time", $__interval),
  MIN(value) AS value
FROM metrics
WHERE
  $__timeFilter("time") AND
  name = 'node_memory_free_pct' AND
  value != 'NaN'
GROUP BY instance, time
ORDER BY instance, time;