#! /bin/bash

LABEL_JSON="${1}" && shift

echo "Found $(cat "${LABEL_JSON}" | wc -l) labels..."

while read -r label_row
do
  labels="$(echo "${label_row}" | jq -r '.labels')"
  name="$(echo ${label_row} | jq -r '.metric_name')"

  IFS='_' read -a LABEL_SEGMENTS <<< "${name}"
  echo "Namespace: ${LABEL_SEGMENTS[0]}"
  echo "Subsystem: ${LABEL_SEGMENTS[1]}"
  echo "Name: ${LABEL_SEGMENTS[@]:2}"
  echo "Labels: ${labels}"
done < ${LABEL_JSON}
