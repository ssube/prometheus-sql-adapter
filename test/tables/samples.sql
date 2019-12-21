BEGIN;
-- describe samples experiment
SELECT plan(3);

\set test_uuid '''00000000-0000-0000-0000-000000000000'''

INSERT INTO metric_labels VALUES (:test_uuid, NOW(), '{"__name__":"foo"}');
INSERT INTO metric_samples VALUES (NOW(), 'foo', (
  SELECT lid FROM metric_labels LIMIT 1
), 512.0);

SELECT results_eq(
  E'SELECT lid, labels->>\'__name__\' FROM metric_labels',
  $$VALUES
    ('00000000-0000-0000-0000-000000000000'::uuid, 'foo')
  $$,
  'labels should match'
);

SELECT results_eq(
  'SELECT lid, name, value FROM metric_samples',
  $$VALUES
    ('00000000-0000-0000-0000-000000000000'::uuid, 'foo', 512.0::float)
  $$,
  'samples should match'
);

SELECT results_eq(
  'SELECT name, value FROM metrics',
  $$VALUES
    ('foo', 512.0::float)
  $$,
  'metrics should match'
);

SELECT * FROM finish();
ROLLBACK;