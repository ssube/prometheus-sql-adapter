ROLE_NAME="${1}" && shift
GRANT_SET="${1}" && shift

echo "Granting ${GRANT_SET} permissions to ${ROLE_NAME}..."
psql -v role_name="${ROLE_NAME}" -f schema/grant/${GRANT_SET}.sql