# Queries

## Contents

- [Queries](#queries)
  - [Contents](#contents)
  - [Getting Started](#getting-started)
    - [Sampling a Single Series](#sampling-a-single-series)
    - [Filtering By Labels](#filtering-by-labels)
    - [Calculating a Delta](#calculating-a-delta)
    - [Joining Multiple Timeseries](#joining-multiple-timeseries)
  - [Details](#details)
    - [Labels Table](#labels-table)
    - [Samples Table](#samples-table)
    - [Metrics View](#metrics-view)
  - [Best Practices](#best-practices)
    - [Continuous Aggregate Patterns](#continuous-aggregate-patterns)
      - [Aggregate Intervals](#aggregate-intervals)
    - [Query Patterns](#query-patterns)
      - [CASE Statements](#case-statements)
      - [Duplicate Samples](#duplicate-samples)
      - [JSON Columns](#json-columns)
      - [Quote Sensitivity](#quote-sensitivity)
      - [Time Filter](#time-filter)
      - [Window Functions](#window-functions)
    - [Grafana Practices](#grafana-practices)
      - [Grafana Errors](#grafana-errors)
        - [JSON Body Marshal](#json-body-marshal)
        - [Data Points Outside Time Range](#data-points-outside-time-range)
      - [Grafana Macros](#grafana-macros)
      - [Result Column Names](#result-column-names)

## Getting Started

### Sampling a Single Series

The simplest query form is a single-series sample select:

```sql
SELECT
  labels->>'instance' AS "metric",
  time_bucket('60s', time) AS "time",
  MAX(value) AS "value"
FROM metrics
WHERE
  time > NOW() - INTERVAL '5 minutes' AND
  name = 'node_load1'
GROUP BY metric, time_bucket('60s', time)
ORDER BY metric, time_bucket('60s', time);
```

The `"time"` and `"name"` filters are necessary to avoid overly - often impossibly - broad table scans. Once the
interesting timeseries(es) have been isolated, they are grouped into time buckets and by relevant labels.

### Filtering By Labels

The labels used for the `"metric"` name are heavily indexed and provide a way to filter timeseries, beyond just their name:

```sql
SELECT
  labels->>'instance' AS "metric",
  time_bucket('60s', time) AS "time",
  MAX(value) AS "value"
FROM metrics
WHERE
  time > NOW() - INTERVAL '5 minutes' AND
  name = 'node_load1' AND
  labels->>'instance' LIKE '10.%'
GROUP BY metric, time_bucket('60s', time)
ORDER BY metric, time_bucket('60s', time);
```

### Calculating a Delta

```sql
SELECT
  labels->>'instance' AS "metric",
  time_bucket('60s', time) AS "time",
  delta(MAX(value)) OVER w AS "value"
FROM metrics
WHERE
  time > NOW() - INTERVAL '5 minutes' AND
  name = 'node_load1' AND
  labels->>'instance' LIKE '10.%'
GROUP BY metric, time_bucket('60s', time)
WINDOW w AS (
  PARTITION BY labels->>'instance'
  ORDER BY time_bucket('60s', time)
);
```

### Joining Multiple Timeseries

Joining a second metric, labels or sample, usually requires aliasing
both series:

```sql
SELECT
  l.labels->>'nodename' AS "metric",
  time_bucket('60s', s.time) AS "time",
  MAX(value) AS "value"
FROM metrics AS s
JOIN metric_labels AS l
ON l.labels->>'__name__' = 'node_uname_info' AND
  l.labels->>'instance' = s.labels->>'instance'
WHERE
  s.time > NOW() - INTERVAL '5 minutes' AND
  name = 'node_load1'
GROUP BY metric, time_bucket('60s', s.time)
ORDER BY metric, time_bucket('60s', s.time);
```

## Details

Two tables contain the data:

- [labels](#labels-table)
- [samples](#samples-table)

Labels for each timeseries are stored once and attached to samples through the `metrics` view.

### Labels Table

The labels table contains the JSON labels that define each timeseries,
deduplicated and identified by their FNV-1a hash.

```sql
\d+ metric_labels

                                         Table "public.metric_labels"
 Column |            Type             | Collation | Nullable | Default | Storage  | Stats target | Description
--------+-----------------------------+-----------+----------+---------+----------+--------------+-------------
 lid    | uuid                        |           | not null |         | plain    |              |
 time   | timestamp without time zone |           | not null |         | plain    |              |
 labels | jsonb                       |           | not null |         | extended |              |
Indexes:
    "metric_labels_lid" UNIQUE, btree (lid)
    "metric_labels_labels" gin (labels)
```

### Samples Table

The samples table contains the sample values and timestamp at which they
were captured by Prometheus.

```sql
\d+ metric_samples

                                         Table "public.metric_samples"
 Column |            Type             | Collation | Nullable | Default | Storage  | Stats target | Description
--------+-----------------------------+-----------+----------+---------+----------+--------------+-------------
 time   | timestamp without time zone |           | not null |         | plain    |              |
 name   | text                        |           | not null |         | extended |              |
 lid    | uuid                        |           | not null |         | plain    |              |
 value  | double precision            |           | not null |         | plain    |              |
Indexes:
    "metric_samples_name_lid_time" btree (name, lid, "time" DESC)
    "metric_samples_time_idx" btree ("time" DESC)
```

### Metrics View

The two tables are joined into a single view, enriching samples with
their labels and providing an easy place to query:

```sql
\d+ metrics

                                     View "public.metrics"
 Column |            Type             | Collation | Nullable | Default | Storage  | Description
--------+-----------------------------+-----------+----------+---------+----------+-------------
 time   | timestamp without time zone |           |          |         | plain    |
 name   | text                        |           |          |         | extended |
 lid    | uuid                        |           |          |         | plain    |
 value  | double precision            |           |          |         | plain    |
 labels | jsonb                       |           |          |         | extended |
View definition:
 SELECT s."time",
    l.labels ->> '__name__'::text AS name,
    s.lid,
    s.value,
    l.labels
   FROM metric_labels l
     JOIN metric_samples s ON s.lid = l.lid
  WHERE s."time" > (now() - '06:00:00'::interval);
```

## Best Practices

### Continuous Aggregate Patterns

#### Aggregate Intervals

Continuous aggregates are calculated on an interval and will have a delay (gap on the right/recent edge of the graph).
The delay will be about `1.5 * (interval + lag)`, giving time for each bucket to fill completely; expect a 15 minute
delay for `5m` interval/lag and up to 45 minutes for `15m`.

### Query Patterns

#### CASE Statements

Using `CASE` statements to join multiple timeseries tend to be extremely slow, since it has to fetch
each series individually or miss the `lid` index, then sort and correlate points between the two.

Avoid this pattern at all costs:

```sql
SELECT
  AVG(bars) / MAX(bins) -- any math over aggregate functions, not just AVG / MAX
FROM (
  SELECT
    ...
    MAX(CASE WHEN name = 'foo_bar' THEN value ELSE null END) AS bars,
    MAX(CASE WHEN name = 'foo_bin' THEN value ELSE null END) AS bins
  FROM metrics
  WHERE
    $__timeFilter("time")
    AND name IN (
      'foo_bar',
      'foo_bin'
    )
  GROUP BY timeGroup, metric
)
```

Matching points between the disparate series causes a repeated quicksort, which can quickly exceed memory
limits and write to disk.

#### Duplicate Samples

Grouping duplicate metrics is necessary when running Prometheus in high-availability sets. Since each Prometheus
instance labels metrics with its own ID, they appear as individual timeseries with different `lid`s, but can be
grouped by time/bucket and metric.

For queries with a single value, momentary or rate:

```sql
SELECT
  labels->>'some_label' AS "metric",
  $__timeGroup(time, ${__interval}) AS "time",
  MAX(value) AS "value"
FROM metrics
WHERE
  $__timeFilter(time) AND
  name = 'some_metric'
GROUP BY $__timeGroup(time, ${__interval}), metric
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
    $__timeGroup("time", ${__interval}),
    value
  FROM metrics
  WHERE
    $__timeFilter(time) AND
    name = 'some_metric'
  GROUP BY $__timeGroup("time", ${__interval}), labels->>'other_label'
) AS s
GROUP BY metric, time
ORDER BY 1, 2
```

#### JSON Columns

The `labels` column has a JSON type and contains all labels related to that metric sample.

To filter on a particular label, use `labels->>'instance' IN ('foo', 'bar')`.

#### Quote Sensitivity

Postgres and Timescale care about quotes and case. Columns should be `"double"`-quoted, literals must be
`'single'`-quoted.

Labels names are literals.

Quotes within a Grafana macro will be retained (although more may be added by the macro).

#### Time Filter

**Always filter by time.**

Timescale stores samples into multiple sub-tables, chunked by time.
Narrowing the time range limits the number of tables that need to be scanned:

```sql
WHERE
  $__timeFilter("time")
  AND metrics.name = 'foo'
ORDER BY metric, time;
```

Within the `WHERE` clause, keep your filters in order by volume of data:

- `time`
- `name`
- `labels`

#### Window Functions

> https://www.postgresql.org/docs/10/tutorial-window.html

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
  rate_time(value, lag(value) OVER w, '${__interval}') AS value
FROM (
  SELECT
    CONCAT(labels->>'instance', labels->>'job') AS metric,
    $__timeGroup("time", ${__interval}) AS bucket,
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

### Grafana Practices

#### Grafana Errors

##### JSON Body Marshal

The JSON body of the query **results** could not be marshalled into numeric data. This typically means that a `NaN` or
`NULL` has leaked into the `"value"`.

Filtering for `NaN` in the outer-most `WHERE` clause should prevent this:

```sql
SELECT
  ...
FROM
  metrics
WHERE
  value != 'NaN'
```

Note that `'NaN'` is a literal string, not a number.

##### Data Points Outside Time Range

As labeled, some of the data points fall outside of the current time range. This can be caused by a `$__timeGroupAlias`
that ends up rounding down by a few seconds, putting metrics outside their window. The easiest fix is to filter by
time in the outer-most `WHERE` (such as a window):

```sql
SELECT
  ...
FROM
  SELECT (
    $__timeGroup("time", '5m')
  ) ...
WHERE
  $__timeFilter("time")
```

#### Grafana Macros

> http://docs.grafana.org/features/datasources/postgres/#macros

Grafana adds a small set of macros for queries to use. These focus on the current time range, granularity, and other
display data that could help optimize queries. Which macros are available is based on the data source.

#### Result Column Names

Metrics have a `name` column with the technical name of the metric, as gathered by Prometheus.

When graphing metrics in Grafana, the `"metric"` column is displayed. Since the same metric is usually gathered across
more than one server or cluster, it can be useful to append some labels to a metric name. For example:

```sql
SELECT
  CONCAT(name, ' - ', labels->>'instance') AS "metric",
  $__time("time"),
  "value"
FROM
  ...
```
