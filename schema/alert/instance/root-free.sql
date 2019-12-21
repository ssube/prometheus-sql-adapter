-- this query relies on the node_pct prometheus rules
SELECT
  l.labels->>'nodename' AS "metric",
  $__timeGroup(m.time, ${__interval}),
  MIN(m.value) AS "value"
FROM metrics AS m
JOIN metrics_labels AS l
  ON l.metric_name = 'node_uname_info' AND 
     m.labels->>'instance' = l.labels->>'instance'
WHERE
  $__timeFilter(m.time) AND
  m.name = 'node_filesystem_free_pct' AND
  m.value != 'NaN'
GROUP BY metric, $__timeGroup(time, ${__interval})
ORDER BY metric, time;

-- this query does not rely on any prometheus rules, but
-- does a slow join across two metrics
SELECT
  REGEXP_REPLACE(instance, '(.+):[0-9]+', '\1') AS "metric",
  time,
  (MIN(available) / AVG(total)) AS "value"
FROM (
  SELECT
    labels->>'instance' AS "instance",
    $__timeGroup("time", ${__interval}),
    CASE WHEN name = 'node_filesystem_free_bytes' THEN value ELSE NULL END AS "available",
    CASE WHEN name = 'node_filesystem_size_bytes' THEN value ELSE NULL END AS "total"
  FROM metrics
  WHERE
    $__timeFilter("time") AND
    name IN (
      'node_filesystem_free_bytes',
      'node_filesystem_size_bytes'
    ) AND
    labels->>'fstype' IN ('xfs', 'ext4') AND
    labels->>'mountpoint' != '/boot' AND
    value != 'NaN'
) t
GROUP BY instance, time
ORDER BY instance, time;
