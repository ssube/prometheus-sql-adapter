-- these views are required for the prometheus-sql-adapter schema
-- to be fully compatible with the pg_prometheus schema

CREATE VIEW metrics_labels AS
SELECT
  l.lid AS id,
  l.labels->>'__name__' AS metric_name,
  l.labels
FROM metric_labels AS l;

CREATE VIEW metrics_values AS
SELECT
  s.lid AS labels_id,
  s.time,
  s.value
FROM metric_samples AS s;