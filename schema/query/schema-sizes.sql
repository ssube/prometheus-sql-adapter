-- get chunk sizes
SELECT
  hypertable_name,
  chunk_name,
  compressed_total_bytes,
  uncompressed_total_bytes
FROM timescaledb_information.compressed_chunk_stats
WHERE compression_status = 'Compressed';

-- get compression ratio
SELECT
  hypertable_name,
  1 - AVG(pg_size_bytes(compressed_total_bytes)::float / pg_size_bytes(uncompressed_total_bytes)) AS compression_ratio
FROM timescaledb_information.compressed_chunk_stats
WHERE compression_status = 'Compressed'
GROUP BY hypertable_name;

-- get labels size
SELECT
  nspname || '.' || relname AS "relation",
  pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size"
FROM pg_class C
LEFT JOIN pg_namespace N
ON (N.oid = C.relnamespace)
WHERE
  nspname NOT IN ('pg_catalog', 'information_schema') AND
  C.relkind <> 'i' AND
  nspname !~ '^pg_toast' AND
  relname LIKE 'metric%'
ORDER BY pg_total_relation_size(C.oid) DESC;

-- get samples size
SELECT
  CONCAT(table_schema, '.', table_name),
  num_dimensions,
  num_chunks,
  total_size
FROM timescaledb_information.hypertable;
-- this can have a WHERE table_name LIKE 'metric%', but that will
-- omit compressed and aggregate hypertables from the list