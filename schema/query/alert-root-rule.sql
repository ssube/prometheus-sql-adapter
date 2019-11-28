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
  m.name = 'node_filesystem_free_pct' AND
  m.value != 'NaN'
GROUP BY instance, m.time
ORDER BY instance, m.time;