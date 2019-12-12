CREATE MATERIALIZED VIEW IF NOT EXISTS cat_name
AS SELECT
  metric_namespace(labels->>'__name__') AS namespace,
  metric_subsystem(labels->>'__name__') AS subsystem,
  metric_name(labels->>'__name__') AS name,
  lid,
  time AS last_seen
FROM metric_labels
WHERE
  labels ? '__name__'
ORDER BY namespace, subsystem, name, lid;