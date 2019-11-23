SELECT
  REGEXP_REPLACE(labels->>'instance', '(.+):[0-9]+', '\1') AS "instance",
  $__timeGroup("time", $__interval),
  MIN(value) AS value
FROM metrics
WHERE
  $__timeFilter("time") AND
  name = 'node_filesystem_avail_pct' AND
  labels->>'fstype' IN ('xfs', 'ext4') AND
  labels->>'mountpoint' != '/boot' AND
  value != 'NaN'
GROUP BY instance, time
ORDER BY instance, time;