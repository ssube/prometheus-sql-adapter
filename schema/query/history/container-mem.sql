SELECT
  a.bucket AS time,
  MAX(a.max_rss) AS value,
  CONCAT(l.labels->>'namespace', '/', l.labels->>'pod_name') AS metric
FROM
  agg_container_mem AS a
JOIN
  metric_labels AS l
ON l.lid = a.lid
WHERE
  $__timeFilter(bucket) AND
  l.labels->>'__name__' = 'container_memory_rss' AND
  l.labels ?& array['namespace', 'pod_name'] AND
  l.labels->>'namespace' IN ($namespace)
GROUP BY bucket, metric
ORDER BY bucket, metric;