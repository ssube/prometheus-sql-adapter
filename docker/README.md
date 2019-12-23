# Docker Images

This directory contains dockerfiles for a few different images, each tagged with
the supported version of Postgres, including the current version and past versions
back to PG10.

## Contents

- [Docker Images](#docker-images)
  - [Contents](#contents)
  - [Architectures](#architectures)
  - [Building Images](#building-images)
  - [Running Images](#running-images)
    - [Jupyter](#jupyter)

## Architectures

- `jupyter` images provide a Jupyter scipy kernel with the Postgres drivers and psycopg2 installed
- `pgtap` images provide a Postgres server with a few extensions installed:
  - [pgTAP](https://pgtap.org/) for testing
  - [pg_prometheus](https://github.com/timescale/pg_prometheus) for collecting metrics
  - [TimescaleDB](https://github.com/timescale/timescaledb) for time-series data
- `postgres` images provide a Postgres server based on the official TimescaleDB images
- `psql` images provide the adapter executable with the `psql` client installed

Both server images (`pgtap` and `postgres`) include the schema setup scripts and
will create a new database if they are started with an empty data directory.

## Building Images

These images are regularly built by CI, but to build them manually:

- set the `IMAGE_ARCH` variable to the `arch-version` suffix
  - for `Dockerfile.jupyter-10`, that would be `jupyter-10`
  - for `Dockerfile.pgtap-11`, that would be `pgtap-11`
  - and so on
- run `make build-image`

This will build, but not push, a tagged image.

## Running Images

### Jupyter

To run the Jupyter lab server with Git and Postgres credentials:

```shell
docker run --rm -it \
  -v $(dirname ${SSH_AUTH_SOCK}):$(dirname ${SSH_AUTH_SOCK}):rw \
  -v $(pwd):/home/jovyan/work:rw \
  -e SSH_AUTH_SOCK=${SSH_AUTH_SOCK} \
  -e PROMSQL_CONNSTR="postgres://user.password@server:port/database" \
  -p 8888:8888 \
  ssube/prometheus-sql-adapter:jupyter-10
```

This will:

- mount your current working directory to `/home/jovyan/work`
- mount your SSH agent for authentication
- provide Postgres connection info in `os.environ.get('PROMSQL_CONNSTR')`
- host the Jupyter Lab UI at http://localhost:8888/lab

**Note**: if `git clone` fails, the Jupyter Lab UI will enter an infinite
busy loop, repeatedly checking the response's status. This will cause the
tab to freeze, and the only error appears in the network debugger. The
only fix appears to be closing the tab.
