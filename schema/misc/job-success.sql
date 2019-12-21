SELECT
  time,
  metric,
  value
FROM (
  SELECT
    time,
    metric,
    (
      CASE
        WHEN lag(value) OVER w IS NULL THEN value
        ELSE value - lag(value) OVER w
      END
    ) AS "value"
  FROM (
    SELECT
      CONCAT(labels->>'namespace', '/', labels->>'job_name') AS "metric",
      $__timeGroup("time", ${__interval}) AS "time",
      MAX(value) AS "value"
    FROM metrics
    WHERE
      $__timeFilter("time") AND
      name = 'kube_job_status_succeeded' AND
      value > 0
    GROUP BY time, metric
  ) AS m
  WINDOW w AS (
    PARTITION BY metric
    ORDER BY time
  )
  ORDER BY time
) AS t
WHERE
  $__timeFilter("time") AND
  value > 0;