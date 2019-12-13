SELECT
  l.labels->>'nodename' AS "metric",
  $__timeGroup(time, $__interval) AS "time",
  MAX("value") AS "value"
FROM metrics AS m
JOIN metrics_labels AS l
ON l.metric_name = 'node_uname_info' AND
    m.labels->>'instance' = l.labels->>'instance'
WHERE
  $__timeFilter("time") AND
  name = 'node_load1' AND
  value != 'NaN'
GROUP BY $__timeGroup(time, $__interval), metric
ORDER BY $__timeGroup(time, $__interval), metric;