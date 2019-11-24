# Prometheus SQL Adapter

Inspired by the [Timescale PostgreSQL adapter](https://github.com/timescale/prometheus-postgresql-adapter) but
compatible with Aurora PostgreSQL, Azure Database for PostgreSQL, and other managed PostgreSQL services.

- keeps a compatible schema with labels in JSONB
- uses Go's SQL package
- uses bulk copy
- does not require `pg_prometheus` extension
- does not use printf to build SQL queries

## Schema

This adapter uses a schema that is compatible with [the Timescale `pg_prometheus` adapter](https://github.com/timescale/prometheus-postgresql-adapter/) but does not require the `pg_prometheus` extension or `SUPERUSER`/plugin permissions.

With v0.2, the metric labels and samples are separated into two data tables and a joining view, linked by a label ID
(`lid`).

The resulting schema can be `\d`escribed as:

```sql
\d+ metric_labels
                                         Table "public.metric_labels"
 Column |            Type             | Collation | Nullable | Default | Storage  | Stats target | Description 
--------+-----------------------------+-----------+----------+---------+----------+--------------+-------------
 lid    | text                        |           | not null |         | extended |              | 
 time   | timestamp without time zone |           | not null |         | plain    |              | 
 labels | jsonb                       |           |          |         | extended |              | 
Indexes:
    "metric_labels_lid" UNIQUE, btree (lid)
    "metric_labels_labels" gin (labels)

\d+ metric_samples
                                         Table "public.metric_samples"
 Column |            Type             | Collation | Nullable | Default | Storage  | Stats target | Description 
--------+-----------------------------+-----------+----------+---------+----------+--------------+-------------
 time   | timestamp without time zone |           | not null |         | plain    |              | 
 name   | text                        |           | not null |         | extended |              | 
 lid    | text                        |           | not null |         | extended |              | 
 value  | double precision            |           |          |         | plain    |              | 
Indexes:
    "metric_samples_name_time_idx" btree (name, "time" DESC)
    "metric_samples_time_idx" btree ("time" DESC)

\d+ metrics
                                     View "public.metrics"
 Column |            Type             | Collation | Nullable | Default | Storage  | Description 
--------+-----------------------------+-----------+----------+---------+----------+-------------
 time   | timestamp without time zone |           |          |         | plain    | 
 name   | text                        |           |          |         | extended | 
 lid    | text                        |           |          |         | extended | 
 value  | double precision            |           |          |         | plain    | 
 labels | jsonb                       |           |          |         | extended | 
View definition:
 SELECT s."time",
    s.name,
    s.lid,
    s.value,
    l.labels
   FROM metric_samples s
     JOIN metric_labels l ON s.lid = l.lid;
```

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

While full tables scans where possible on the test data's labels, missing that index may become costly for larger
clusters.

### Row Size

Samples were taken from an 8 node, 90 pod cluster being monitored by a single Prometheus replica, for roughly an
8-hour period of low overnight usage. Approximately 2.13 million samples were collected per hourly chunk, or 18.13
million total.

Sample rows weighed an average of `262.55` bytes after chunking and indexing, but without compression. The `lid`
column is a consistent 29 bytes, while the `name` varies between 38 and 69 bytes.

These samples had 32793 unique label sets (`lid`s), of which 54.71% were still active by the end. Label rows weighed
an average of `2686.95` bytes after indexing (BTREE for the `lid`, GIN for the `labels`), or 84MB total.

Removing labels from the samples table and deduplicating them yielded a 59.75% reduction in total disk space.

### Further Research

Removing the `name` from `metric_samples` would reduce row size further and make each row an identical 45 bytes
(before indexing), with `lid` replacing it in the `(time, name, time)` index. This would, however, require the
query planner to hit `metric_labels` first, then `metric_samples` using the `(lid, time)` within each chunk (Timescale
itself plans the first `time` to a set of chunks).
