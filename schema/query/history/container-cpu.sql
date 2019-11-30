SELECT
  a.bucket AS time,
  a.delta_usage AS value,
  CONCAT(l.labels->>'namespace', '/', l.labels->>'pod') AS metric
FROM
  agg_container_cpu AS a
JOIN
  metric_labels AS l
ON l.lid = a.lid
WHERE l.labels ? 'pod';