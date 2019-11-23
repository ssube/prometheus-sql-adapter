SELECT
  NOW() AS time,
  relname AS metric,
  n_live_tup AS value
FROM pg_stat_all_tables;