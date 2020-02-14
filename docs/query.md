# Getting Started

## Contents

- Where did that plugin go?

## Basics

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

## Gotchas

### Schema Gotchas

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

Windows allow Postgres to compare the same metric, filtered by labels, across time.

Any filters and most renaming should be done within an inner select, with the other select used to handle the
window and counter resets.

### Grafana

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
