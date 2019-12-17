BEGIN;
SELECT plan(1);

SELECT is(rate_time(10, 0, '10 seconds'), 1.0::float, '0 -> 10 over 10s is 1');

SELECT * FROM finish();
ROLLBACK;
