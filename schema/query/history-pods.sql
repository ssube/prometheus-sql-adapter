SELECT
  a.bucket AS time,
  a.pods,
  REGEXP_REPLACE(l.labels->>'instance', '(.+):[0-9]+', '\1') AS metric
FROM
  agg_load AS a
JOIN
  metric_labels AS l
ON l.lid = a.lid;