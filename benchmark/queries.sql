\timing

SELECT
  l.labels->>'nodename' AS "metric",
  m."time",
  MAX("value") AS "value"
FROM (
  SELECT
    labels->>'instance' AS instance,
    time_bucket('5m', "time"),
    value
  FROM metrics
  WHERE
    time > NOw() - INTERVAL '6 hours' AND
    name = 'node_load1' AND
    value != 'NaN'
) AS m
JOIN metrics_labels AS l
  ON l.metric_name = 'node_uname_info' AND
     instance = l.labels->>'instance'
GROUP BY metric, m.time
ORDER BY metric, m.time;


SELECT
  l.labels->>'nodename' AS "instance",
  time_bucket('5m', m."time") AS "time",
  MIN(m.value) AS value
FROM metrics AS m
JOIN metrics_labels AS l
  ON l.metric_name = 'node_uname_info' AND 
     m.labels->>'instance' = l.labels->>'instance'
WHERE
  m.time > NOw() - INTERVAL '6 hours' AND
  m.name = 'node_memory_free_pct' AND
  m.value != 'NaN'
GROUP BY instance, m.time
ORDER BY instance, m.time;


SELECT
  l.labels->>'nodename' AS "instance",
  time_bucket('5m', m."time") AS "time",
  MIN(m.value) AS value
FROM metrics AS m
JOIN metrics_labels AS l
  ON l.metric_name = 'node_uname_info' AND 
     m.labels->>'instance' = l.labels->>'instance'
WHERE
  m.time > NOW() - INTERVAL '6 hours' AND
  m.name = 'node_filesystem_free_pct' AND
  m.value != 'NaN'
GROUP BY instance, m.time
ORDER BY instance, m.time;