# Prometheus SQL Adapter

Adapter to connect [Prometheus' remote write endpoint](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write)
to a PostgreSQL server, preferably running [TimescaleDB](https://www.timescale.com/). Caches labels for each timeseries to reduce
writes, linking them to samples by metric fingerprint.

This adapter was inspired by the [Timescale PostgreSQL adapter](https://github.com/timescale/prometheus-postgresql-adapter)
and maintains a compatible schema, so queries may be used with either, but this adapter does not require the
`pg_prometheus` extension, making it compatible with Aurora PostgreSQL, Azure Database for PostgreSQL, and other
managed PostgreSQL services.

While it is possible to use this adapter and most of the schema without TimescaleDB, it will become difficult to
prune older data, compression will not be available, and queries will be slower. If you can use TimescaleDB, please do.

## Features

- batteries included
  - schema and grant setup scripts
  - queries for alerting, historical reports, schema metadata
  - Grafana dashboards for Kubernetes cluster, schema metadata
  - Prometheus rules for derived metrics
- compatible schema
  - query compatible with Timescale's official `pg_prometheus` schema
  - does not require `pg_prometheus` extension
  - does not require superuser or extension privileges
- efficient storage
  - hashed & cached label IDs
  - samples in compressed hypertable
  - uses Go SQL and bulk copy for samples

## Getting Started

- run TimescaleDB somewhere, like [a Kubernetes pod](kubernetes/README.md) or [Timescale Cloud](https://www.timescale.com/cloud)
- set the `PG*` environment variables for your connection info (`PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`)
- create a database
- run `./scripts/schema-create.sh [license-level] [retain-live] [retain-total]`
- create a role for each set of adapters to write
- run `./scripts/schema-grant.sh [role-name] adapter`
- create a role for each Grafana instance to read
- run `./scripts/schema-grant.sh [role-name] grafana`
- create a role for each human instance to read
- run `./scripts/schema-grant.sh [role-name] human`

The schema scripts are idempotent and safe to run repeatedly, including `schema-create.sh`.

Non-breaking upgrades can be performed by running the schema scripts again, in the same order.

## Contents

- [Prometheus SQL Adapter](#prometheus-sql-adapter)
  - [Features](#features)
  - [Getting Started](#getting-started)
  - [Contents](#contents)
  - [Status](#status)
  - [Schema](#schema)
    - [Tables](#tables)
    - [Views](#views)

## Status

[![pipeline status](https://git.apextoaster.com/ssube/prometheus-sql-adapter/badges/feat/xx-split-labels/pipeline.svg)](https://git.apextoaster.com/ssube/prometheus-sql-adapter/commits/feat/xx-split-labels)
[![Renovate badge](https://badges.renovateapi.com/github/ssube/isolex)](https://renovatebot.com)
[![MIT license](https://img.shields.io/github/license/ssube/prometheus-sql-adapter.svg?color=brightgreen)](https://github.com/ssube/prometheus-sql-adapter/blob/master/LICENSE.md)

[![Open bug count](https://img.shields.io/github/issues-raw/ssube/prometheus-sql-adapter/type-bug.svg)](https://github.com/ssube/prometheus-sql-adapter/issues?q=is%3Aopen+is%3Aissue+label%3Atype%2Fbug)
[![Open issue count](https://img.shields.io/github/issues-raw/ssube/prometheus-sql-adapter.svg)](https://github.com/ssube/prometheus-sql-adapter/issues?q=is%3Aopen+is%3Aissue)
[![Closed issue count](https://img.shields.io/github/issues-closed-raw/ssube/prometheus-sql-adapter.svg?color=brightgreen)](https://github.com/ssube/prometheus-sql-adapter/issues?q=is%3Aissue+is%3Aclosed)

## Schema

This adapter uses a schema that is compatible with [the Timescale `pg_prometheus` adapter](https://github.com/timescale/prometheus-postgresql-adapter/) but does not require the `pg_prometheus` extension or `SUPERUSER`/plugin permissions.

### Tables

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
    l.labels ->> '__name__'::text AS name,
    s.lid,
    s.value,
    l.labels
   FROM metric_labels l
     JOIN metric_samples s ON s.lid = l.lid
  WHERE s."time" > (now() - '06:00:00'::interval);
```

The `metrics` view makes this compatible with the original `pg_prometheus` schema and the v0.1 schema
(which featured a single `metrics` table with both value and labels).

Maximum time ranges may be enforced by the `metrics` view to limit the amount of raw data that can be fetched at
once, but deduplication and aggregation typically need context to determine the correct operators, and must happen
later.

Samples are linked to their labels using the metric's hashed fingerprint, or label ID (`lid`). This is provided by
the Prometheus SDK and uses the 64-bit FNV-1a hash, which is then stored as a UUID column. The adapters each
maintain an LRU cache of recently written label sets, stored by `lid`, and avoid re-`INSERT`ing previously seen
label sets.

Using the metric's fingerprint provides a short, deterministic identifier for each label set, or timeseries. The
adapters do not need to coordinate and can safely write in parallel, using an `ON CONFLICT` clause to skip or
update existing label sets. While a numeric counter might be shorter than the current hash-as-UUID, it would require
coordination between the adapters or within the database.

Each label set in `metric_labels` has the metric's name in the `__name__` key, so there is no `name` column in that
table. To search by name, replace `WHERE name = 'foo'` clauses with the JSON field access `labels->>'__name__' = 'foo'`,
which will hit the `metric_labels_name_lid` index. While full tables scans were possible in the test cluster, which
had 34k labels weighing 95MB, missing that index may become costly for larger clusters. The total size of the
`metric_labels` table is the number of unique timeseries being written.

### Views

Views within the schema are split into three groups: aggregated samples, materialized catalogs of the schema, and
compatibility with the `pg_prometheus` schema.

Aggregate views are prefixed with `agg_` and use TimescaleDB's continuous aggregates to occasionally refresh a
materialized view and aggregate samples into larger time buckets.

Catalog views are prefixed with `cat_` and materialize expensive views of the metric labels, enriching them with
collected metadata.

Compatibility views ensure the schema is fully compatible with the `pg_prometheus` extensions' schema, despite slightly
different underlying storage.