-- this query relies on the node_pct prometheus rules
SELECT
  l.labels->>'nodename' AS "metric",
  $__timeGroup(m.time, ${__interval}) AS "time",
  MIN(m.value) AS "value"
FROM metrics AS m
JOIN metrics_labels AS l
  ON l.metric_name = 'node_uname_info' AND
     m.labels->>'instance' = l.labels->>'instance'
WHERE
  $__timeFilter(m.time) AND
  m.name = 'node_memory_free_pct' AND
  m.value != 'NaN'
GROUP BY metric, $__timeGroup(m.time, ${__interval})
ORDER BY metric, time;

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
    $__timeGroup("time", ${__interval}),
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