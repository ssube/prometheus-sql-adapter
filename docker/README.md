# Docker Images

This directory contains dockerfiles for a few different images, each tagged with
the supported version of Postgres, including the current version and past versions
back to PG10.

- `jupyter` images provide a Jupyter scipy kernel with the Postgres drivers and psycopg2 installed
- `pgtap` images provide a Postgres server with a few extensions installed:
  - [pgTAP](https://pgtap.org/) for testing
  - [pg_prometheus](https://github.com/timescale/pg_prometheus) for collecting metrics
  - [TimescaleDB](https://github.com/timescale/timescaledb) for time-series data
- `postgres` images provide a Postgres server based on the official TimescaleDB images
- `psql` images provide the adapter executable with the `psql` client installed

Both server images (`pgtap` and `postgres`) include the schema setup scripts and
will create a new database if they are started with an empty data directory.
