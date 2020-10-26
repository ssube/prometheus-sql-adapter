# **NOTICE: THIS PROJECT HAS BEEN SUPERSEDED BY PROMSCALE**

This project has been superseded by [Promscale](https://github.com/timescale/Promscale). 
Like this project, Promscale allows easy storage of Prometheus metrics in TimescaleDB + Postgres, 
but also offers: automatic partitioning, native compression (typically 95% storage savings), 
native data retention policies, full SQL and PromQL, and more.

You can find the new project at [https://github.com/timescale/promscale](https://github.com/timescale/promscale) 
and more details can be found in the [design document](https://tsdb.co/prom-design-doc).

This project will continue only in maintenance mode.

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
  - example queries for alerting, reports, and schema metadata
  - Grafana dashboards for Kubernetes workloads, hardware metrics, and schema metadata
  - Jupyter notebooks for long-term reporting
  - PostgreSQL server image with schema and grant setup scripts
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

- create the schema:
  - deploy `kubernetes/server.yml`
  - or `docker run --rm -p 5432:5432 ssube/prometheus-sql-adapter:master-postgres-11 -c 'shared_preload_libraries=timescaledb'`
  - or run `./scripts/schema-create [license-level] [retain-live] [retain-total]` against an existing database
- configure adapters:
  - create a role for each set of adapters to write
  - run `./scripts/schema-grant.sh [role-name] adapter`
  - deploy `kubernetes/adapter.yml`
- configure Grafana:
  - create a role for each Grafana instance to read
  - run `./scripts/schema-grant.sh [role-name] grafana`
  - add a Postgres data source
  - import dashboards from `grafana/`
- configure humans:
  - create a role for each developer to read
  - run `./scripts/schema-grant.sh [role-name] human`
  - show off your sweet new graphs

The schema scripts are idempotent and safe to run repeatedly, including `schema-create.sh`.

Non-breaking upgrades can be performed by running the schema scripts again, in the same order.

## Contents

- [Prometheus SQL Adapter](#prometheus-sql-adapter)
  - [Features](#features)
  - [Getting Started](#getting-started)
  - [Contents](#contents)
  - [Status](#status)
  - [Releases](#releases)
  - [Schema](#schema)
    - [Views](#views)

## Status

[![Pipeline status](https://git.apextoaster.com/ssube/prometheus-sql-adapter/badges/master/pipeline.svg)](https://git.apextoaster.com/ssube/prometheus-sql-adapter/commits/master)
[![Test coverage](https://codecov.io/gh/ssube/prometheus-sql-adapter/branch/master/graph/badge.svg)](https://codecov.io/gh/ssube/prometheus-sql-adapter)
[![MIT license](https://img.shields.io/github/license/ssube/prometheus-sql-adapter.svg?color=brightgreen)](https://github.com/ssube/prometheus-sql-adapter/blob/master/LICENSE.md)

[![Open bug count](https://img.shields.io/github/issues-raw/ssube/prometheus-sql-adapter/type-bug.svg)](https://github.com/ssube/prometheus-sql-adapter/issues?q=is%3Aopen+is%3Aissue+label%3Atype%2Fbug)
[![Open issue count](https://img.shields.io/github/issues-raw/ssube/prometheus-sql-adapter.svg)](https://github.com/ssube/prometheus-sql-adapter/issues?q=is%3Aopen+is%3Aissue)
[![Closed issue count](https://img.shields.io/github/issues-closed-raw/ssube/prometheus-sql-adapter.svg?color=brightgreen)](https://github.com/ssube/prometheus-sql-adapter/issues?q=is%3Aissue+is%3Aclosed)

[![Renovate badge](https://badges.renovateapi.com/github/ssube/prometheus-sql-adapter)](https://renovatebot.com)
[![Dependency status](https://img.shields.io/david/ssube/prometheus-sql-adapter.svg)](https://david-dm.org/ssube/prometheus-sql-adapter)
[![Dev dependency status](https://img.shields.io/david/dev/ssube/prometheus-sql-adapter.svg)](https://david-dm.org/ssube/prometheus-sql-adapter?type=dev)
[![Known vulnerabilities](https://snyk.io/test/github/ssube/prometheus-sql-adapter/badge.svg)](https://snyk.io/test/github/ssube/prometheus-sql-adapter)

[![Maintainability](https://api.codeclimate.com/v1/badges/8d8cef3deeb64827440b/maintainability)](https://codeclimate.com/github/ssube/prometheus-sql-adapter/maintainability)
[![Technical debt ratio](https://img.shields.io/codeclimate/tech-debt/ssube/prometheus-sql-adapter.svg)](https://codeclimate.com/github/ssube/prometheus-sql-adapter/trends/technical_debt)
[![Quality issues](https://img.shields.io/codeclimate/issues/ssube/prometheus-sql-adapter.svg)](https://codeclimate.com/github/ssube/prometheus-sql-adapter/issues)

## Releases

[![github release link](https://img.shields.io/badge/github-release-blue?logo=github)](https://github.com/ssube/prometheus-sql-adapter/releases)
[![github release version](https://img.shields.io/github/tag/ssube/prometheus-sql-adapter.svg)](https://github.com/ssube/prometheus-sql-adapter/releases)
[![github commits since release](https://img.shields.io/github/commits-since/ssube/prometheus-sql-adapter/v0.4.0.svg)](https://github.com/ssube/prometheus-sql-adapter/compare/v0.4.0...master)

[![docker image link](https://img.shields.io/badge/docker-image-blue?logo=docker)](https://hub.docker.com/r/ssube/prometheus-sql-adapter)
[![docker image size](https://images.microbadger.com/badges/image/ssube/prometheus-sql-adapter:master.svg)](https://microbadger.com/images/ssube/prometheus-sql-adapter:master)

## Schema

This schema is compatible with [the Timescale `pg_prometheus` adapter](https://github.com/timescale/prometheus-postgresql-adapter/)
but does not require the `pg_prometheus` extension or `SUPERUSER` permissions.

Captured labels and samples are split into two tables, with labels stored uniquely and identified by their FNV-1a
hash, to which samples are tied.

Labels are stored once for each timeseries using the metric's hashed fingerprint, or label ID (`lid`). This is
provided by the Prometheus SDK and uses the 64-bit FNV-1a hash, which is then stored as a UUID column. The remote
write adapters each maintain an LRU cache of label IDs, and can be configured not to rewrite labels.

Using the metric's fingerprint provides a short, deterministic identifier for each label set, or timeseries. The
adapters do not need to coordinate and can safely write in parallel, using an `ON CONFLICT` clause to skip or
update existing label sets. While a numeric counter might be shorter than the current hash-as-UUID, it would
require coordination between the adapters or within the database. The hashed `lid` avoids lookups when writing to
an existing timeseries.

Maximum time ranges may be enforced by the `metrics` view to limit the amount of raw data that can be fetched at
once, but deduplication and aggregation typically need more context to determine the correct operators, and must
happen later. The maximum range allowed by `metrics` is used for the compression policy as well, compacting data
when it can no longer be queried directly. Finally, the view makes this schema compatible with the original
`pg_prometheus` schema and the v0.1 schema (which featured a single `metrics` table with both value and labels).

### Views

Views within the schema are split into three groups: aggregated samples, materialized catalogs of the schema, and
compatibility with the `pg_prometheus` schema.

Aggregate views are prefixed with `agg_` and use TimescaleDB's continuous aggregates to occasionally refresh a
materialized view and aggregate samples into larger time buckets.

Catalog views are prefixed with `cat_` and materialize expensive views of the metric labels, enriching them with
collected metadata.

Compatibility views ensure the schema is fully compatible with the `pg_prometheus` extensions' schema, despite slightly
different underlying storage.
