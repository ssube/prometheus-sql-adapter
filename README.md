# Prometheus SQL Adapter

Inspired by the [Timescale PostgreSQL adapter](https://github.com/timescale/prometheus-postgresql-adapter) but
compatible with Aurora PostgreSQL, Azure Database for PostgreSQL, and other managed PostgreSQL services.

- keeps a compatible schema with labels in JSONB
- uses Go's SQL package
- uses bulk copy
- does not require `pg_prometheus` extension
- does not use printf to build SQL queries