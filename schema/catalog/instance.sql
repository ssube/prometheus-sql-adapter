CREATE MATERIALIZED VIEW IF NOT EXISTS cat_instance
AS SELECT
  u.labels->>'nodename' AS node,
  REGEXP_REPLACE(l.labels->>'instance', '(.*):.*', '\1') AS instance,
  l.labels->>'__name__' AS name,
  l.lid,
  MAX(l.time) AS last_seen
FROM metric_labels AS l
JOIN metric_labels AS u
ON
  u.labels->>'__name__' = 'node_uname_info' AND
  u.labels->>'instance' = l.labels->>'instance'
WHERE
  l.labels ?& array['__name__', 'instance']
GROUP BY node, instance, name, l.lid
ORDER BY node, instance, name, l.lid;