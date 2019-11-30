SELECT
  l.labels->>'nodename' AS "metric",
  $__timeGroup(m.time, $__interval),
  MAX(m.value) AS "value"
FROM metrics AS m
JOIN metrics_labels AS l
  ON l.metric_name = 'node_uname_info' AND
     m.labels->>'instance' = l.labels->>'instance'
WHERE
  $__timeFilter(m.time) AND
  m.name = 'node_load1' AND
  m.value != 'NaN'
GROUP BY metric, $__timeGroup(m.time, $__interval)
ORDER BY metric, time;