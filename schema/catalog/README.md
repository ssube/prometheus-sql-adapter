# Catalog Views

These are occasionally-materialized views that provide a prepared catalog of resources: instances, pods, or
simply timeseries themselves. While available from labels, these may be expensive to compute in their
split form, and may be enriched with metadata from other metrics (node hostname, kernel version, or EC2 tags).
