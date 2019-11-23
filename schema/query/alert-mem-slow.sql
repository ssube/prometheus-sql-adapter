SELECT
  REGEXP_REPLACE(instance, '(.+):[0-9]+', '\1') AS "metric",
  time,
  (MIN(available) / MIN(total)) AS "value"
FROM
(
  SELECT
    metrics.labels->>'instance' AS "instance",
    $__timeGroup("time", $__interval),
    case when name = 'node_memory_MemAvailable_bytes' then value else null end as "available",
    case when name = 'node_memory_MemTotal_bytes' then value else null end as "total"
  FROM metrics
  WHERE
    $__timeFilter("time") AND
    name IN (
      'node_memory_MemAvailable_bytes',
      'node_memory_MemTotal_bytes'
    ) AND
    value != 'NaN'
) t
GROUP BY instance, time
ORDER BY instance, time;