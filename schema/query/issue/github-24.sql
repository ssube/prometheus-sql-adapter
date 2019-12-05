EXPLAIN ANALYZE SELECT
  a.bucket AS time,
  MAX(a.max_rss) AS value,
  CONCAT(l.labels->>'namespace', '/', l.labels->>'pod_name') AS metric
FROM
  metric_labels AS l
JOIN
  agg_container_mem AS a
ON a.lid = l.lid
WHERE
  bucket BETWEEN '2019-12-04T00:16:47.421Z' AND '2019-12-05T00:16:47.421Z' AND
  l.labels->>'__name__' = 'container_memory_rss' AND
  l.labels->>'namespace' NOT IN ('build-jobs', 'gitlab-jobs', 'kube-system')
GROUP BY bucket, metric
ORDER BY bucket, metric;

-- optimized by:
-- checking name first
-- then label presence (no idea why that matters)
-- then label values
EXPLAIN ANALYZE SELECT
  a.bucket AS time,
  MAX(a.delta_usage) AS value,
  CONCAT(l.labels->>'namespace', '/', l.labels->>'pod_name') AS metric
FROM agg_container_cpu AS a
JOIN metric_labels AS l
ON l.lid = a.lid
WHERE 
  bucket BETWEEN '2019-12-04T01:13:44.306Z' AND '2019-12-05T01:13:44.307Z' AND 
  l.labels->>'__name__' = 'container_cpu_usage_seconds_total' AND
  l.labels ?& array['namespace', 'pod_name'] AND 
  l.labels->>'namespace' IN ('monitoring','build-jobs')
GROUP BY bucket, metric
ORDER BY bucket, metric;
