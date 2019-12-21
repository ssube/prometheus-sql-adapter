SELECT
  CONCAT(labels->>'pod', '/', labels->>'container') AS metric,
  $__timeGroup(time, ${__interval}),
  value / 100000
FROM metrics
WHERE
  $__timeFilter(time) AND 
  name = 'container_spec_cpu_quota' AND
  labels ? 'container' AND
  value > 0
ORDER BY $__timeGroup(time, ${__interval}), metric;

SELECT
  CONCAT(labels->>'pod', '/', labels->>'container') AS metric,
  $__timeGroup(time, ${__interval}),
  value
FROM metrics
WHERE
  $__timeFilter(time) AND 
  name = 'container_spec_memory_limit_bytes' AND
  labels ? 'container' AND
  value > 0
ORDER BY $__timeGroup(time, ${__interval}), metric;

SELECT
  CONCAT(labels->>'pod', '/', labels->>'container') AS metric,
  MAX(value) AS value
FROM metrics
WHERE
  $__timeFilter(time) AND 
  name = 'container_spec_memory_limit_bytes' AND
  labels ? 'container' AND
  labels->>'container' NOT IN ('POD', 'helper', 'svc-0') AND
  value = 0
GROUP BY metric
ORDER BY metric;