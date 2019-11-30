SELECT
  MAX(table_name) AS metric,
  to_timestamp(lower(ranges[1])/10^6) AS time,
  SUM(total_bytes)
FROM _timescaledb_catalog.hypertable, chunk_relation_size(table_name::text)
WHERE
  table_name LIKE 'metric%' AND to_timestamp(lower(ranges[1])/10^6) > NOW() - INTERVAL '6 hours'
GROUP BY time
ORDER BY metric, time;

SELECT
  hypertable_name,
  chunk_name,
  compressed_total_bytes,
  uncompressed_total_bytes
FROM timescaledb_information.compressed_chunk_stats;