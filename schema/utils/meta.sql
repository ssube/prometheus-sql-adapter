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