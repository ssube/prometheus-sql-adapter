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
  WHERE bucket < NOW() - INTERVAL '1 day'
  ORDER BY lid, bucket
) UNION ALL (
  SELECT
    lid,
    bucket AS time,
    max_load AS value
  FROM
    agg_instance_load
  WHERE bucket > NOW() - INTERVAL '1 day'
  ORDER BY lid, bucket
) UNION ALL (
  SELECT
    lid,
    "tg" AS "time",
    MAX("value") AS "value"
  FROM (
    SELECT
      lid,
      time_bucket(INTERVAL '1 minute', time) AS "tg",
      value
    FROM metrics
    WHERE
      time > NOW() - INTERVAL '15 minutes'
      AND name = 'node_load1'
      AND value != 'NaN'
  ) t
  GROUP BY lid, time
  ORDER BY lid, time
)) AS s
JOIN metric_labels AS l
ON l.lid = s.lid
ORDER BY s.time, s.lid;