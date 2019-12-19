BEGIN;
-- describe rate_time helper
SELECT plan(5);

\set test_interval '''10 seconds'''

-- it should handle simple rates
SELECT is(rate_time(10, 0, :test_interval), 1.0::float, '0 -> 10 over 10s is 1');
-- it should handle negative values
SELECT is(rate_time(60, -60, '2 minutes'), 1.0::float, '-60 -> 60 over 2m is 1');
-- it should handle counter resets
SELECT is(rate_time(40, 900, '20 seconds'), 2.0::float, '900 -> reset -> 40 over 20s is 2');
-- it should handle null lag samples
SELECT is(rate_time(40, NULL, :test_interval), NULL, 'null lag sample is null');
-- it should handle null last samples
SELECT is(rate_time(NULL, 40, :test_interval), NULL, 'null last sample is null');

SELECT * FROM finish();
ROLLBACK;
