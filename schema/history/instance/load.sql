SELECT
  l.labels->>'instance' AS metric,
  s.time,
  s.value
FROM ((
  SELECT
    lid,
    bucket AS time,
    max_load AS value
  FROM
    agg_instance_load_long
  WHERE
    $__timeFilter(bucket) AND
    bucket < NOW() - INTERVAL '1 day'
  ORDER BY lid, bucket
) UNION ALL (
  SELECT
    lid,
    bucket AS time,
    max_load AS value
  FROM
    agg_instance_load
  WHERE
    $__timeFilter(bucket) AND
    bucket > NOW() - INTERVAL '1 day'
  ORDER BY lid, bucket
) UNION ALL (
  SELECT
    lid,
    bucket AS "time",
    MAX("value") AS "value"
  FROM (
    SELECT
      lid,
      $__timeGroup(time, ${__interval}) AS bucket,
      value
    FROM metrics
    WHERE
      $__timeFilter(time) AND
      time > NOW() - INTERVAL '15 minutes' AND
      name = 'node_load1' AND
      value != 'NaN'
  ) t
  GROUP BY lid, time
  ORDER BY lid, time
)) AS s
JOIN metric_labels AS l
ON l.lid = s.lid
ORDER BY s.time, s.lid;