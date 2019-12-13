SELECT
  CONCAT(labels->>'node', '/', labels->>'pod', '/', labels->>'container_name') AS metric, 
  time_bucket('$__interval', time) AS time, 
  MAX(value) * 100
FROM metrics 
WHERE 
  name = 'container_cpu_cfs_throttled_rate_pct' AND 
  labels ? 'container_name'
GROUP BY time_bucket('$__interval', time), metric 
ORDER BY time_bucket('$__interval', time), metric;