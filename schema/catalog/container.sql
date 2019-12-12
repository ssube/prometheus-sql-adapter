CREATE MATERIALIZED VIEW IF NOT EXISTS cat_container
AS SELECT
  labels->>'namespace' AS namespace,
  labels->>'pod_name' AS pod,
  labels->>'container_name' AS container,
  instance_host(labels->>'instance') AS instance,
  labels->>'__name__' AS name,
  lid,
  MAX(time) AS last_seen
FROM metric_labels
WHERE
  labels ?& array['namespace', 'pod_name', 'container_name'] AND
  labels->>'container_name' != 'POD'
GROUP BY namespace, pod, container, instance, name, lid
ORDER BY namespace, pod, container, instance, name, lid;