BEGIN;
-- describe time_interval helper
SELECT plan(2);

-- it should handle parse strings
SELECT is(interval_seconds('10 seconds'), 10::float, '10 seconds');
-- it should convert larger units to epoch seconds
SELECT is(interval_seconds('2 minutes'), 120::float, '120 seconds');

SELECT * FROM finish();
ROLLBACK;

