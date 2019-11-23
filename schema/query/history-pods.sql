SELECT
  a.bucket AS time,
  a.pods AS pods,
  REGEXP_REPLACE(l.labels->>'instance', '(.+):[0-9]+', '\1') AS instance
FROM
  agg_load AS a
JOIN
  metric_labels AS l
ON l.lid = a.lid;