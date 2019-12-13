SELECT
  a.bucket AS time,
  a.pods AS pods,
  instance_host(l.labels->>'instance') AS instance
FROM
  agg_instance_pods AS a
JOIN
  metric_labels AS l
ON l.lid = a.lid;