-- get compression ratio
SELECT
  hypertable_name,
  1 - AVG(pg_size_bytes(compressed_total_bytes)::float / pg_size_bytes(uncompressed_total_bytes)) AS compression_ratio
FROM timescaledb_information.compressed_chunk_stats
WHERE compression_status = 'Compressed'
GROUP BY hypertable_name;