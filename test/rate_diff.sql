BEGIN;
-- describe rate_diff helper
SELECT plan(5);

-- it should calculate simple diff
SELECT is(rate_diff(10, 0), 10::float, '0 -> 10 is 10');
-- it should handle negative endpoints
SELECT is(rate_diff(60, -60), 120::float, '-60 -> 60 is 120');
-- it should handle counter resets
SELECT is(rate_diff(40, 900), 40::float, '900 -> reset -> 40 is 40');
-- it should handle null lag samples
SELECT is(rate_diff(40, NULL), NULL, 'null lag sample is null');
-- it should handle null last samples
SELECT is(rate_diff(NULL, 40), NULL, 'null last sample is null');

SELECT * FROM finish();
ROLLBACK;