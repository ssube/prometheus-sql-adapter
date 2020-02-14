LICENSE_LEVEL="${1:-community}"     # community, enterprise (use enterprise for cloud)

RETAIN_LIVE="${2:-'6 hours'}"       # uncompressed chunks
RETAIN_TOTAL="${3:-'30 days'}"      # compressed chunks

read -r VERSION_MAJOR VERSION_MINOR VERSION_PATCH < <( ./scripts/package-version.sh )
export VERSION_MAJOR
export VERSION_MINOR
export VERSION_PATCH
export VERSION_TAG=''

if [[ "${SKIP_TABLES:-}" != "TRUE" ]];
then
  echo "Creating tables..."
  psql \
    -v retain_live="${RETAIN_LIVE}" \
    -v retain_total="${RETAIN_TOTAL}" \
    -f schema/tables.sql
fi

if [[ -n "${COMPAT_TYPE:-}" ]];
then
  echo "Creating compatibility views..."
  psql -f schema/compat/${COMPAT_TYPE}.sql
fi

echo "Creating utility functions..."
psql -f schema/utils/time.sql
psql -f schema/utils/rate.sql

psql -f schema/utils/instance.sql
psql -f schema/utils/metric.sql

echo "Creating metadata for schema v${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}..."
psql \
  -f <(cat schema/utils/meta.sql | envsubst)

if [[ "${SKIP_CAGGS:-}" != "TRUE" ]];
then
  echo "Creating continuous aggregates..."
  # container caggs
  psql -f schema/cagg/container/cpu.sql
  psql -f schema/cagg/container/mem.sql
  # grafana caggs
  psql -f schema/cagg/grafana/alert.sql
  # instance caggs
  psql -f schema/cagg/instance/load.sql
  psql -f schema/cagg/instance/pods.sql
  # deployment caggs
  psql -f schema/cagg/deployment/pod_count.sql
fi

if [[ "${SKIP_CATALOG:-}" != "TRUE" ]];
then
  echo "Creating catalog views..."
  psql -f schema/catalog/container.sql
  psql -f schema/catalog/instance.sql
  psql -f schema/catalog/name.sql
fi

if [[ "${LICENSE_LEVEL}" == "enterprise" ]];
then
  echo "Creating drop policy..."
  psql \
    -v retain_live="${RETAIN_LIVE}" \
    -v retain_total="${RETAIN_TOTAL}" \
    -f schema/prune.sql
else
  echo "Creating a drop_chunks policy requires TimescaleDB cloud or enterprise."
  echo "You may need to set up a cronjob in Kubernetes or SystemD to prune old data."
  echo "Please refer to the docs for more info: https://docs.timescale.com/latest/using-timescaledb/data-retention"
fi
