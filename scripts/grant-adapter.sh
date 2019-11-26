ROLE_NAME="${1}" && shift

echo "Granting necessary permissions for an adapter to ${ROLE_NAME}..."
psql -v role_name="${ROLE_NAME}" -f schema/grant/adapter.sql