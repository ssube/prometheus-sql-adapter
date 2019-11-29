SELECT
  l.labels->>'nodename' AS "metric",
  m."time",
  MAX("value") AS "value"
FROM (
  SELECT
    labels->>'instance' AS instance,
    lid,
    $__timeGroup("time", $__interval),
    value
  FROM metrics
  WHERE
    $__timeFilter("time") AND
    name = 'node_load1' AND
    value != 'NaN'
) AS m
JOIN metric_labels AS l
  ON l.labels->>'__name__' = 'node_uname_info' AND
     instance = l.labels->>'instance'
GROUP BY metric, m.time
ORDER BY metric, m.time;