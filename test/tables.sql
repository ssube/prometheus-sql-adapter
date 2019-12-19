BEGIN;
-- describe tables
SELECT plan(5);

-- it should have a metric_labels table
SELECT has_table('public', 'metric_labels', 'metric_labels should exist');
-- it should have a metric_samples table
SELECT has_table('public', 'metric_samples', 'metric_samples should exist');

-- it should have indexes on metric_labels
SELECT indexes_are('public', 'metric_labels', ARRAY[
  'metric_labels_lid',
  'metric_labels_labels',
  'metric_labels_instance_lid',
  'metric_labels_name_lid',
  'metric_labels_name_namespace_podname' -- TODO: should be _podname_lid
]);
-- it should have indexes on metric_samples
SELECT indexes_are('public', 'metric_samples', ARRAY[
  'metric_samples_lid_time',
  'metric_samples_name_time',
  'metric_samples_time_idx' -- added by timescale's default indexes option
]);

-- should have a single dimension
SELECT is(
  (
    SELECT num_dimensions
    FROM timescaledb_information.hypertable
    WHERE
      table_schema = 'public' AND
      table_name = 'metric_samples'
  ),
  1::smallint
);

SELECT * FROM finish();
ROLLBACK;

