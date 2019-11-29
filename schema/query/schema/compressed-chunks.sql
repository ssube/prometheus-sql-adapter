-- get chunk sizes
SELECT
  hypertable_name,
  chunk_name,
  compressed_total_bytes,
  uncompressed_total_bytes
FROM timescaledb_information.compressed_chunk_stats
WHERE compression_status = 'Compressed';