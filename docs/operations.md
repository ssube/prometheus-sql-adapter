# Operations

## Contents

- [Operations](#operations)
  - [Contents](#contents)
  - [Connecting](#connecting)
    - [Kubernetes](#kubernetes)
      - [Bundled Server](#bundled-server)
    - [Timescale Cloud](#timescale-cloud)
  - [Setup](#setup)
    - [Creating Schema](#creating-schema)
    - [Creating Adapter Role (Writer)](#creating-adapter-role-writer)
    - [Creating Grafana Role (Reader)](#creating-grafana-role-reader)
    - [Creating Human Role (Reader)](#creating-human-role-reader)
  - [Maintenance](#maintenance)
    - [Updating Schema](#updating-schema)
    - [Updating Role](#updating-role)
  - [Extending](#extending)
    - [Additional Continuous Aggregates (caggs)](#additional-continuous-aggregates-caggs)
    - [Additional Roles](#additional-roles)

## Connecting

Running the schema scripts requires `psql`, which is available in both the `:master-psql-11` (write adapter) and
`:master-postgres-11` (server) containers, as well as through `apt` and `brew`.

### Kubernetes

To run the scripts against a Timescale server running in Kubernetes, forward a port to the pod and connect through
the resulting tunnel.

```shell
k port-forward -n test-schema timescale-server 5432:5432 &

PGHOST=localhost PGPORT=5432 ./scripts/schema-create.sh
```

This requires standard authentication with a `PGUSER` and `PGPASSWORD`.

#### Bundled Server

If the server is using the `ssube/prometheus-sql-adapter:master-postgres-11` server image, the schema is available
under the `/app` directory.

Scripts can be executed from a shell on the server container:

```shell
k exec -it -n test-schema timescale-server -- bash

cd /app
PGUSER=postgres ./scripts/schema-create.sh
```

This does not require a `PGPASSWORD`, as local connections from `postgres` are trusted.

### Timescale Cloud

To run the scripts against a Timescale Cloud instance, fetch the connection info from the service overview page:
https://portal.timescale.cloud/project/example-project/services/metrics-ingest/overview

- export `host` as `PGHOST`
- export `port` as `PGPORT`
- export `user` (usually `tsdbadmin`) as `PGUSER`
- export `password` as `PGPASSWORD`

## Setup

### Creating Schema

To create the schema within an existing Timescale instance and database:

```shell
PGHOST=hostname.origin.com PGPORT=5432 PGUSER=user.name PGDATABASE=prometheus ./scripts/schema-create.sh [license-level]
```

### Creating Adapter Role (Writer)

To create a suitable role for the remote-write adapter:

```shell
PGHOST=hostname.origin.com PGPORT=5432 PGUSER=user.name PGDATABASE=prometheus ./scripts/schema-grant.sh [role-name] adapter
```

### Creating Grafana Role (Reader)

To create a suitable role for a Grafana reader:

```shell
PGHOST=hostname.origin.com PGPORT=5432 PGUSER=user.name PGDATABASE=prometheus ./scripts/schema-grant.sh [role-name] grafana
```

The Grafana role grants access to read metrics from the time-limited view and raw labels, with a query timeout that
defaults to 60 seconds.

### Creating Human Role (Reader)

To create a suitable role for a human reader:

```shell
PGHOST=hostname.origin.com PGPORT=5432 PGUSER=user.name PGDATABASE=prometheus ./scripts/schema-grant.sh [role-name] human
```

The human role grants similar access to [the Grafana role](#creating-grafana-role-reader), reducing the query timeout
to 30 seconds for interactive queries.

## Maintenance

### Updating Schema

The `./scripts/schema-create.sh` script is idempotent, using `CREATE IF NOT EXISTS` and `CREATE OR REPLACE` wherever
possible. For regular updates and schema additions, simply run this script again with connection info:

```shell
PGHOST=hostname.origin.com PGPORT=5432 PGUSER=user.name PGDATABASE=prometheus ./scripts/schema-create.sh [license-level]
```

The `schema-create` script does not remove existing indices, nor does it alter existing tables. No suitable tool has
been found yet for complex schema changes, most being part of an ORM or introducing a dependency on Java.

### Updating Role

The `./scripts/schema-grant.sh` script is idempotent, using primarily `GRANT` statements. For regular updates and
schema additions, simply run this script again with connection info:

```shell
PGHOST=hostname.origin.com PGPORT=5432 PGUSER=user.name PGDATABASE=prometheus ./scripts/schema-grant.sh [role-name] grafana
```

## Extending

### Additional Continuous Aggregates (caggs)

To add a new cagg, create a file in the subdirectory of `schema/cagg` which corresponds to the metric's namespace and
subsystem (`node_load1` should be in `schema/cagg/node/load1.sql`, `kube_deployment_status_foo` should be in
`schema/cagg/kube/deployment/foo.sql`, etc). If the same aggregate exists with multiple intervals, suffix the filename
with the `timescaledb.refresh_interval` as written in the SQL (`15m`, `1h`, etc).

Continuous aggregates should select samples from `metric_samples` and group by the `lid` and a `time_bucket`, leaving
the labels to be attached later, like so:

```sql
CREATE VIEW agg_namespace_subsystem
WITH (
  timescaledb.continuous,
  timescaledb.refresh_interval = '15m',
  timescaledb.refresh_lag = '15m')
) AS SELECT
  lid,
  time_bucket('15 minutes', time) AS "bucket",
  -- value columns
FROM metric_samples
WHERE
  name = 'namespace_subsystem_metric'
GROUP BY lid, bucket;
```

This prevents duplication of the label data, while ensuring all label indices remain available to the aggregated data.

### Additional Roles

To add a new role `${ROLE_NAME}`, create a file named `schema/grant/${ROLE_NAME}.sql` with the necessary `GRANT`
statements:

```sql
GRANT SELECT ON metric_samples TO :role_name
```

Make sure to use `:role_name` in place of the role's name.

To extend an existing role:

```sql
\i schema/grant/grafana.sql

GRANT ...
```

Roles are not applied by default and do not need to be added to any script.
