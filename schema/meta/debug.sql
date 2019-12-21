SELECT CONCAT(major, '.', minor, '.', patch) AS schema_version FROM prom_sql_version();
SELECT * FROM prom_sql_size();
SELECT * FROM prom_sql_compress_ratio();