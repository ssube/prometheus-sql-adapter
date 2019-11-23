SELECT
  REGEXP_REPLACE(instance, '(.+):[0-9]+', '\1') AS "metric",
  time,
  (MIN(available) / AVG(total)) AS "value"
FROM (
  SELECT
    labels->>'instance' AS "instance",
    $__timeGroup("time", $__interval),
    CASE WHEN name = 'node_filesystem_free_bytes' THEN value ELSE NULL END AS "available",
    CASE WHEN name = 'node_filesystem_size_bytes' THEN value ELSE NULL END AS "total"
  FROM metrics
  WHERE
    $__timeFilter("time") AND
    name IN (
      'node_filesystem_free_bytes',
      'node_filesystem_size_bytes'
    ) AND
    labels->>'fstype' IN ('xfs', 'ext4') AND
    labels->>'mountpoint' != '/boot' AND
    value != 'NaN'
) t
GROUP BY instance, time
ORDER BY instance, time;