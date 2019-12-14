# Metrics

## Contents

- [Metrics](#metrics)
  - [Contents](#contents)
  - [Metric Labels](#metric-labels)
  - [Metric Names](#metric-names)
    - [Useful Name Prefixes](#useful-name-prefixes)
    - [Useful Individual Names](#useful-individual-names)

## Metric Labels

- `__name__`: metric name
- `container_name`
- `instance`: source instance IP:port, use `instance_host` to extract IP
- `job`: source job, SD key in Prometheus
- `namespace`
- `nodename`: only available on `node_uname_info`, see join
- `pod_name`
- `service`

## Metric Names

The adapter allows metric to be filtered by name prefix. Stopping on an `_` will filter by namespace, subsystem,
or child group within the Prometheus hierarchy.

### Useful Name Prefixes

- `adapter_`: metrics from the SQL adapter itself
- `container_`
  - `cpu_cfs_`: per-container CPU shares and throttling
  - `cpu_usage_`: per-container CPU shares and usage
  - `memory_`: per-container memory metrics
  - `spec_`: per-container resource requests and limits
- `grafana_`: Grafana query and alert metrics
- `go_`: metrics from Go services
- `kube_*_status_`: metrics related to k8s resource status and errors
- `kubelet_`: metrics from each k8s node's kubelet
- `node_`: metrics from each k8s node
- `nodejs_`: metrics from NodeJS services
- `process_`: process-level metrics
- `prometheus_`: Prometheus query and rule metrics

### Useful Individual Names

- `container_cpu_cfs_throttled_periods_total` and derived `container_cpu_cfs_throttled_rate_pct`
- `container_cpu_cfs_periods_total`
- `container_cpu_usage_seconds_total`
- `container_memory_rss`
- `container_spec_cpu_quota`
- `container_spec_memory_limit_bytes`
- `node_disk_write_time_seconds_total`
- `node_filesystem_free_bytes`
- `node_filesystem_size_bytes`
- `node_load1`
- `node_memory_avail_bytes`/`_total` and derived `_pct`
- `node_memory_free_bytes`/`_total` and derived `_pct`
- `node_uname_info`
