DO $$ BEGIN
  CREATE TYPE prom_sql_semver AS (major integer, minor integer, patch integer, tag TEXT);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION prom_sql_version() RETURNS prom_sql_semver
AS $$
  SELECT ${VERSION_MAJOR}, ${VERSION_MINOR}, ${VERSION_PATCH}, '';
$$
LANGUAGE SQL
IMMUTABLE
CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION prom_sql_size_all() RETURNS TABLE (
  table_name text,
  total_size bigint
) AS $$
  SELECT
    nspname || '.' || relname AS "table_name",
    pg_total_relation_size(C.oid) AS "total_size"
  FROM pg_class C
  LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
  WHERE nspname NOT IN ('pg_catalog', 'information_schema')
    AND C.relkind <> 'i'
    AND nspname !~ '^pg_toast'
  ORDER BY total_size DESC;
$$
LANGUAGE SQL
VOLATILE
CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION prom_sql_size_total() RETURNS numeric
AS $$
  SELECT SUM(total_size) FROM prom_sql_size_all();
$$
LANGUAGE SQL
VOLATILE
CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION prom_sql_size_labels() RETURNS TABLE (
  table_name text,
  total_size bigint
) AS $$
  SELECT 'metric_labels', pg_total_relation_size('metric_labels');
$$
LANGUAGE SQL
VOLATILE
CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION prom_sql_size_samples() RETURNS TABLE (
  table_name TEXT,
  total_size bigint,
  table_size bigint,
  index_size bigint,
  toast_size bigint
) AS $$
  SELECT
    CONCAT(hypertable.table_schema::text, '.', hypertable.table_name::text) AS table_name,
    pg_size_bytes(hypertable.total_size) AS total_size,
    pg_size_bytes(hypertable.table_size) AS table_size,
    pg_size_bytes(hypertable.index_size) AS index_size,
    pg_size_bytes(hypertable.toast_size) AS toast_size
  FROM 
    timescaledb_information.hypertable AS hypertable,
    hypertable_approximate_row_count(CONCAT(hypertable.table_schema::text, '.', hypertable.table_name::text)) AS counts
  WHERE hypertable.table_size != ''
  ORDER BY hypertable.index_size DESC;
$$
LANGUAGE SQL
VOLATILE
CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION prom_sql_size() RETURNS TABLE (
  table_name TEXT,
  total_size bigint
) AS $$
  SELECT
    table_name,
    total_size
  FROM ((
    SELECT
      table_name,
      total_size
    FROM prom_sql_size_labels()
  ) UNION ALL (
    SELECT
      table_name,
      total_size
    FROM prom_sql_size_samples()
  ) UNION ALL (
    SELECT
      '__total' AS table_name,
      prom_sql_size_total()::bigint AS total_size
  )) AS s
$$
LANGUAGE SQL
VOLATILE
CALLED ON NULL INPUT;