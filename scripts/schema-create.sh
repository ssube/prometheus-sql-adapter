LICENSE_LEVEL="${1:-community}"

echo "Creating tables..."
psql \
  -v retain_live="'6 hours'" \
  -v retain_total="'30 days'" \
  -f schema/tables.sql

if [[ "${LICENSE_LEVEL}" == "enterprise" ]];
then
  echo "Creating drop policy..."
  psql \
    -v retain_live="'6 hours'" \
    -v retain_total="'30 days'" \
    -f schema/tables.sql
else
  echo "You may need to set up a cronjob in Kubernetes or SystemD to prune old data."
  echo "Creating a drop_chunks policy requires TimescaleDB cloud or enterprise."
  echo "Please refer to the docs for more info: https://docs.timescale.com/latest/using-timescaledb/data-retention"
fi

echo "Creating continuous aggregates..."
psql -f schema/views/instance-load.sql
psql -f schema/views/instance-pods.sql