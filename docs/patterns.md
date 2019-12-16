# Query Patterns

## Continuous Aggregates

Continuous aggregates are calculated on an interval and will have a delay (gap on the right/recent edge of the graph).
The delay will be about `1.5 * (interval + lag)`, giving time for each bucket to fill completely; expect a 15 minute
delay for `5m` interval/lag and up to 45 minutes for `15m`.

## Deduplication

Grouping duplicate metrics is necessary when running Prometheus in high-availability sets. Since each Prometheus
instance labels metrics with its own ID, they appear as individual timeseries with different `lid`s, but can be
grouped by time/bucket and metric.

For queries with a single value, momentary or rate:

```sql
SELECT
  labels->>'some_label' AS "metric",
  $__timeGroup(time, $__interval) AS "time",
  MAX(value) AS "value"
FROM metrics
WHERE
  $__timeFilter(time) AND
  name = 'some_metric'
GROUP BY $__timeGroup(time, $__interval), metric
ORDER BY 1, 2
```

For queries with multiple values or a complex aggregate:

```sql
SELECT
  metric,
  time,
  MAX(value) AS "value"
FROM (
  SELECT
    labels->>'some_label' AS "metric",
    $__timeGroup("time", $__interval),
    value
  FROM metrics
  WHERE
    $__timeFilter(time) AND
    name = 'some_metric'
  GROUP BY $__timeGroup("time", $__interval), labels->>'other_label'
) AS s
GROUP BY metric, time
ORDER BY 1, 2
```

## Window Functions

Window functions allow aggregates to view more than one row at a time, often using the previous and/or next row
to calculate change over time. Larger windows may calculate ordered aggregates like percentiles, but also need to
look at a larger set of rows and may not scale well.

Some utility functions are provided in [the `rate_` family](../schema/utils/rate.sql) to calculate change between
samples, handle counter resets, and adjust for time.

Time buckets should be grouped in a sub-select before the window function:

```sql
SELECT
  metric,
  bucket AS time,
  rate_time(value, lag(value) OVER w, '$__interval') AS value
FROM (
  SELECT
    CONCAT(labels->>'instance', labels->>'job') AS metric,
    $__timeGroup("time", $__interval) AS bucket,
    MAX(value) AS value
  FROM metrics
  WHERE
    $__timeFilter("time") AND
    name = 'node_disk_write_time_seconds_total'
  GROUP BY metric, bucket
) AS m
WINDOW w AS (PARTITION BY metric ORDER BY bucket)
ORDER BY metric, time;
```
