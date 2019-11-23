SELECT NOW() AS time, active.count / total.count AS value
FROM (
  SELECT COUNT(1)::float AS count FROM metric_labels
) AS total, (
  SELECT COUNT(1)::float AS count FROM metric_labels WHERE time > NOW() - INTERVAL '5 minutes'
) AS active;