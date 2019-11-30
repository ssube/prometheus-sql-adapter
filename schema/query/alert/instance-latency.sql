-- this query gets disk latency
SELECT
  metric,
  time,
  (
    CASE
      WHEN value >= lag(value) OVER w
        THEN value - lag(value) OVER w
      WHEN lag(value) OVER w IS NULL THEN NULL
      ELSE value
    END
  ) / EXTRACT(epoch FROM interval '$__interval') AS "value"
FROM (
  SELECT
    CONCAT(l.labels->>'nodename', ' ', m.labels->>'device') AS "metric",
    $__timeGroupAlias("time", $__interval, previous),
    MAX(value) AS "value"
  FROM metrics AS m
  JOIN metrics_labels AS l
    ON l.metric_name = 'node_uname_info' AND
       m.labels->>'instance' = l.labels->>'instance'
  WHERE
    $__timeFilter("time") AND
    name='node_disk_write_time_seconds_total'
  GROUP BY metric, $__timeGroup("time", $__interval)
  ORDER BY metric, time
) AS metrics
WINDOW w as (PARTITION BY metric ORDER BY time)
ORDER BY metric, time;