# Query Patterns

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
