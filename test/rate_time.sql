BEGIN;
SELECT plan(3);

-- should handle simple rates
SELECT is(rate_time(10, 0, '10 seconds'), 1.0::float, '0 -> 10 over 10s is 1');
-- should handle negative values
SELECT is(rate_time(60, -60, '2 minutes'), 1.0::float, '-60 -> 60 over 2m is 1');
-- should handle counter resets
SELECT is(rate_time(40, 900, '20 seconds'), 2.0::float, '900 -> reset -> 40 over 20s is 2');

SELECT * FROM finish();
ROLLBACK;
