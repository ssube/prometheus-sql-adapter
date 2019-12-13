-- get the hostname from a host:port instance label
CREATE OR REPLACE FUNCTION instance_host(t TEXT) RETURNS TEXT
AS $$
  SELECT REGEXP_REPLACE(t, '(.*):[0-9]+', '\1')
$$
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT;