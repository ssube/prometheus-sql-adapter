PSQL_DATABASE="${1}" && shift

echo "Creating tables..."
psql -f schema/tables.sql

echo "Creating compression policy..."
psql -f schema/compress.sql

echo "Creating continuous aggregates..."
psql -f schema/views/instance-load.sql
psql -f schema/views/instance-pods.sql