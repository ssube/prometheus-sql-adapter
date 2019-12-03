LICENSE_LEVEL="${1:-community}"     # community, enterprise (use enterprise for cloud)

RETAIN_LIVE="${2:-'6 hours'}"       # uncompressed chunks
RETAIN_TOTAL="${3:-'30 days'}"      # compressed chunks

echo "Creating tables..."
psql \
  -v retain_live="${RETAIN_LIVE}" \
  -v retain_total="${RETAIN_TOTAL}" \
  -f schema/tables.sql

if [[ "${LICENSE_LEVEL}" == "enterprise" ]];
then
  echo "Creating drop policy..."
  psql \
    -v retain_live="${RETAIN_LIVE}" \
    -v retain_total="${RETAIN_TOTAL}" \
    -f schema/prune.sql
else
  echo "You may need to set up a cronjob in Kubernetes or SystemD to prune old data."
  echo "Creating a drop_chunks policy requires TimescaleDB cloud or enterprise."
  echo "Please refer to the docs for more info: https://docs.timescale.com/latest/using-timescaledb/data-retention"
fi

echo "Creating continuous aggregates..."
psql -f schema/views/container/cpu.sql
psql -f schema/views/container/mem.sql

psql -f schema/views/instance/load.sql
psql -f schema/views/instance/pods.sql