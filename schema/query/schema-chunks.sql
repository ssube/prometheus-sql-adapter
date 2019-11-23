SELECT 
  MAX(table_name) AS metric,
  to_timestamp(lower(ranges[1])/10^6) AS time,
  SUM(total_bytes)
FROM _timescaledb_catalog.hypertable, chunk_relation_size(table_name::text) 
WHERE 
  table_name LIKE 'metric%' 
GROUP BY time 
ORDER BY metric, time;