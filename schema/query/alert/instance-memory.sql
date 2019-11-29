-- this query relies on the node_pct prometheus rules
SELECT
  l.labels->>'nodename' AS "instance",
  $__timeGroup(m."time", $__interval),
  MIN(m.value) AS value
FROM metrics AS m
JOIN metric_labels AS l
  ON l.labels->>'__name__' = 'node_uname_info' AND
     m.labels->>'instance' = l.labels->>'instance'
WHERE
  $__timeFilter(m."time") AND
  m.name = 'node_memory_free_pct' AND
  m.value != 'NaN'
GROUP BY instance, m.time
ORDER BY instance, m.time;

-- this query does not need any prometheus rules, but
-- does a low join across two metrics
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