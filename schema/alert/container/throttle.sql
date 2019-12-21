SELECT
  CONCAT(labels->>'node', '/', labels->>'pod', '/', labels->>'container_name') AS metric,
  $__timeGroup(time, ${__interval}) AS time,
  MAX(value) * 100
FROM metrics
WHERE
  name = 'container_cpu_cfs_throttled_rate_pct' AND
  labels ? 'container_name'
GROUP BY $__timeGroup(time, ${__interval}), metric
ORDER BY $__timeGroup(time, ${__interval}), metric;