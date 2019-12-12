CREATE MATERIALIZED VIEW IF NOT EXISTS cat_container
AS SELECT
  labels->>'namespace' AS namespace,
  labels->>'pod_name' AS pod,
  labels->>'container_name' AS container,
  labels->>'instance' AS instance,
  lid,
  MAX(time) AS last_seen
FROM metric_labels
WHERE
  labels ?& array['namespace', 'pod_name', 'container_name'] AND
  labels->>'container_name' != 'POD'
GROUP BY namespace, pod, container, instance, lid
ORDER BY namespace, pod, container, instance, lid;