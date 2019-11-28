# Prometheus SQL Adapter

Adapter to connect [Prometheus' remote write endpoint](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)
to a PostgreSQL server, preferably running [TimescaleDB](https://www.timescale.com/). Caches labels for each timeseries to reduce
writes, linking them to samples by metric fingerprint.

This adapter was inspired by the [Timescale PostgreSQL adapter](https://github.com/timescale/prometheus-postgresql-adapter),
but does not require the `pg_prometheus` extension, making it compatible with
Aurora PostgreSQL, Azure Database for PostgreSQL, and other managed PostgreSQL services.

While it is possible to use this adapter and most of the schema without TimescaleDB, it will become difficult to
prune older data, compression will not be available, and queries will be slower. If you can use TimescaleDB, please do.

## Features

- query compatible with `pg_prometheus` schema
- hashed label IDs to deduplicate
- normalized labels to support compression
- uses Go's SQL package
- uses bulk copy for samples
- does not require `pg_prometheus` extension
- does not use printf to build SQL queries

## Status

[![pipeline status](https://git.apextoaster.com/ssube/prometheus-sql-adapter/badges/feat/xx-split-labels/pipeline.svg)](https://git.apextoaster.com/ssube/prometheus-sql-adapter/commits/feat/xx-split-labels)

## Contents

- [Prometheus SQL Adapter](#prometheus-sql-adapter)
  - [Features](#features)
  - [Status](#status)
  - [Contents](#contents)
  - [Schema](#schema)
    - [Label ID](#label-id)

## Schema

This adapter uses a schema that is compatible with [the Timescale `pg_prometheus` adapter](https://github.com/timescale/prometheus-postgresql-adapter/) but does not require the `pg_prometheus` extension or `SUPERUSER`/plugin permissions.

The metric labels and samples are separated into two data tables and a joining view, linked by a label ID (`lid`). The
resulting schema can be described as:

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
    s.name,
    s.lid,
    s.value,
    l.labels
   FROM metric_samples s
     JOIN metric_labels l ON s.lid = l.lid
  WHERE s."time" > (now() - '06:00:00'::interval);
```

The `metrics` view makes this compatible with the original `pg_prometheus` schema and the v0.1 schema
(which featured a single `metrics` table with both value and labels).

Maximum time ranges and minimum time buckets may be enforced by the `metrics` view to limit the amount of
raw data that can be fetched at once, but deduplication and aggregation typically need context to determine
the correct operators, and must happen later.

### Label ID

Where [the original schema](https://github.com/timescale/prometheus-postgresql-adapter/blob/master/pkg/postgresql/client.go#L72)
uses a temporary table and `INSERT INTO %s_labels (metric_name, labels)`, this schema links the samples with their
labels using a hashed label ID. The `lid` is generated by calling the Prometheus metric's `String()` method, then
taking the base64-encoded SHA-1 hash of the results. This provides a short, deterministic identifier for each unique
set of labels at the cost of some CPU (less than `100m` per 1k samples/sec on an old Xeon E3-1245v2).

The metric string hashed to produce `lid` includes the metric name - twice, as the string prefix and `__name__`
label - and provides a constant-length key to be indexed and easily skipped with `ON CONFLICT DO NOTHING`. The `lid`
also provides a natural order and segment key for later chunk reordering and compression.

While a numeric label might be shorter still, it would require coordination between the adapters or a database lock.
The hashed `lid` avoids the need for a cluster and leader elections.

Similarly, each set of labels has a `__name__` label, containing the metric name. This avoids the need for a `name`
column and corresponding index in the `metric_labels` table, but `name = 'foo'` conditions must be replaced with
`labels @> '{"__name__":"foo"}'`.

```sql
# EXPLAIN SELECT * FROM metric_labels WHERE labels->>'__name__' = 'node_load1';
                             QUERY PLAN                             
--------------------------------------------------------------------
 Seq Scan on metric_labels  (cost=0.00..8574.43 rows=164 width=410)
   Filter: ((labels ->> '__name__'::text) = 'node_load1'::text)
(2 rows)

# EXPLAIN SELECT * FROM metric_labels WHERE labels @> '{"__name__": "node_load1"}';
                                     QUERY PLAN                                      
-------------------------------------------------------------------------------------
 Bitmap Heap Scan on metric_labels  (cost=15.65..52.16 rows=33 width=410)
   Recheck Cond: (labels @> '{"__name__": "node_load1"}'::jsonb)
   ->  Bitmap Index Scan on metric_labels_labels  (cost=0.00..15.65 rows=33 width=0)
         Index Cond: (labels @> '{"__name__": "node_load1"}'::jsonb)
(4 rows)
```

While full tables scans were possible in the test cluster, which had 34k labels weighing 95MB, missing that index
may become costly for larger clusters.
