#! /bin/bash
set -e

(
  cd /app && \
  PGUSER="${POSTGRES_USER}" \
  PGDATABASE="${POSTGRES_DB}" \
  ./scripts/schema-create.sh
)