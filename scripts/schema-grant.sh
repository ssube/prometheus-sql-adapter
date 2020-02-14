#! /bin/bash

ROLE_NAME="${1}"
GRANT_SET="${2:-grafana}"

TIMEOUT_HUMAN="${3:-30000}"
TIMEOUT_ROBOT="${4:-60000}"

echo "Granting ${GRANT_SET} permissions to ${ROLE_NAME}..."
psql \
  -v role_name="${ROLE_NAME}" \
  -v timeout_human="${TIMEOUT_HUMAN}" \
  -v timeout_robot="${TIMEOUT_ROBOT}" \
  -f schema/grant/${GRANT_SET}.sql