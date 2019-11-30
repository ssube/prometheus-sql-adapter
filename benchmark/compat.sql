-- this view is required for full compatibility with the
-- pg_prometheus schema
CREATE VIEW metrics_labels AS
SELECT
  l.lid AS id,
  l.labels->>'__name__' AS metric_name,
  labels
FROM metric_labels AS l;