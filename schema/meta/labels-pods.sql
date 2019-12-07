SELECT COUNT(
  DISTINCT(
    labels->>'namespace',
    labels->>'pod_name'
  )
)
FROM metric_labels
WHERE
  labels->>'__name__' = 'container_memory_rss' AND
  labels ?& array['namespace', 'pod_name'];