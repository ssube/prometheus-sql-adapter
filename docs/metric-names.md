# Metric Names

The adapter allows metric to be filtered by name prefix. Stopping on an `_` will filter by namespace, subsystem,
or child group within the Prometheus hierarchy.

## Useful Names

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
