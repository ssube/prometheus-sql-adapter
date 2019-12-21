-- these views are required for the pg_prometheus schema
-- to be fullly compatible with the prometheus-sql-adapter schema

CREATE VIEW metric_labels AS
SELECT
  l.id AS lid,
  l.metric_name AS name, -- TODO: add this to labels
  l.labels
FROM metrics_labels AS l;

CREATE VIEW metric_samples AS
SELECT
  s.labels_id AS lid,
  s.time,
  s.value
FROM metrics_values AS s;