# Sizes

## Row Size

Samples were taken from an 8 node, 90 pod cluster being monitored by a single Prometheus replica, for roughly an
8-hour period of low overnight usage. Approximately 2.13 million samples were collected per hourly chunk, or 18.13
million total.

Sample rows weighed an average of `262.55` bytes after chunking and indexing, but without compression. The `lid`
column is a consistent 29 bytes, while the `name` varies between 38 and 69 bytes.

These samples had 32793 unique label sets (`lid`s), of which 54.71% were still active by the end. Label rows weighed
an average of `2686.95` bytes after indexing (BTREE for the `lid`, GIN for the `labels`), or 84MB total.

Removing labels from the samples table and deduplicating them yielded a 59.75% reduction in total disk space.

Enabling compression on the `metric_samples` table for chunks older than 6 hours, using `orderby = 'time'` and
`segmentby = 'lid'`, brought each chunk from 530MB to below 10MB:

```sql
SELECT
  hypertable_name,
  chunk_name,
  compressed_total_bytes,
  uncompressed_total_bytes
FROM timescaledb_information.compressed_chunk_stats
WHERE compression_status = 'Compressed';

 hypertable_name |               chunk_name                | compressed_total_bytes | uncompressed_total_bytes 
-----------------+-----------------------------------------+------------------------+--------------------------
 metric_samples  | _timescaledb_internal._hyper_1_54_chunk | 9680 kB                | 530 MB
 metric_samples  | _timescaledb_internal._hyper_1_57_chunk | 9712 kB                | 531 MB
 metric_samples  | _timescaledb_internal._hyper_1_58_chunk | 9632 kB                | 530 MB
 metric_samples  | _timescaledb_internal._hyper_1_59_chunk | 9744 kB                | 529 MB
 metric_samples  | _timescaledb_internal._hyper_1_60_chunk | 9616 kB                | 530 MB
(5 rows)

SELECT
  hypertable_name,
  chunk_name,
  pg_size_bytes(uncompressed_total_bytes)::float / pg_size_bytes(compressed_total_bytes) AS compression_ratio
FROM timescaledb_information.compressed_chunk_stats
WHERE compression_status = 'Compressed';

 hypertable_name |               chunk_name                | compression_ratio 
-----------------+-----------------------------------------+-------------------
 metric_samples  | _timescaledb_internal._hyper_1_54_chunk |  0.98216391509434
 metric_samples  | _timescaledb_internal._hyper_1_57_chunk | 0.982138653483992
 metric_samples  | _timescaledb_internal._hyper_1_58_chunk | 0.982252358490566
 metric_samples  | _timescaledb_internal._hyper_1_59_chunk | 0.982012051039698
 metric_samples  | _timescaledb_internal._hyper_1_60_chunk | 0.982281839622641
(5 rows)
```

Compression yielded a 98.21% reduction in total disk space. The `GROUP BY lid ORDER BY time DESC` causes each
timeseries, or unique set of labels, to be grouped together and time order often allows delta compression.
For short enough chunks, this results in a small number of samples: less than 2000 per timeseries
in the test cluster. The compressed chunk usually had one row per active timeseries, indicating that most or
all samples could be compressed together (the `lid` and thus the `name` are constant and can be stored once).

When the last 6 hours are considered live for a 24 hour retention period for full resolution samples, the final
reduction in disk space was 84.14% compared to the previous schema. This becomes more effective as the ratio of
active to compressed chunks decreases, with a 94.00% reduction for a 72 hour retention period and upwards of 97%
for a 10 day retention period.

## Further Research

- Removing the `name` from `metric_samples` would reduce row size further and make each row an identical 45 bytes
  (before indexing), with `lid` replacing it in the `(time, name, time)` index. This would, however, require the
  query planner to hit `metric_labels` first, then `metric_samples` using the `(lid, time)` within each chunk
  (Timescale itself plans the first `time` to a set of chunks).

- Putting `metric_labels` into a hypertable would allow Timescale to drop or compress old labels automatically,
  but each insert could bump a row from an old chunk into a new one, which seems like a performance problem and
  would make it difficult to compress chunks. Most `lid`s remain inactive when they have not been used in a few
  minutes, when their pod or job completes, but there are no guarantees around that.

- Using a TTL cache rather than LRU (or 2Q) would allow the adapter to drop old label sets after some time. The
  maximum size provided to the LRU cache prevents labels from accumulating without limit over time, but does
  nothing to evict labels that have not been seen recently.