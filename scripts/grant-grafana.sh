ROLE_NAME="${1}" && shift

echo "Granting necessary permissions for Grafana to ${ROLE_NAME}..."
psql -v role_name="${ROLE_NAME}" -f schema/grant/grafana.sql