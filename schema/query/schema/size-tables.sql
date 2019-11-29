-- get table sizes
SELECT
  CONCAT(table_schema, '.', table_name),
  num_dimensions,
  num_chunks,
  total_size
FROM timescaledb_information.hypertable;
-- this can have a WHERE table_name LIKE 'metric%', but that will
-- omit compressed and aggregate hypertables from the list