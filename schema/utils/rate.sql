-- find the rate of change, accounting for resets
-- usage: rate_diff(value, lag(value) OVER w)
CREATE OR REPLACE FUNCTION rate_diff(last_sample float, lag_sample float) RETURNS float
AS $$
  SELECT CASE
    WHEN last_sample >= lag_sample THEN last_sample - lag_sample      -- rising edge
    WHEN lag_sample IS NULL THEN NULL                                 -- leading gap
    ELSE last_sample                                                  -- falling edge/reset
  END
$$
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT;

-- find the rate of change, accounting for leading resets and 0s (but requires both lag and lead rows)
-- using "Null value: connected" in Grafana has a similar effect without fetching an extra row
-- usage: rate_smooth(value, lag(value) OVER w, lead(value) OVER w)
CREATE OR REPLACE FUNCTION rate_smooth(last_sample float, lag_sample float, lead_sample float) RETURNS float
AS $$
  SELECT CASE
    WHEN lag_sample IS NULL THEN rate_diff(lead_sample, last_sample)
    ELSE rate_diff(last_sample, lag_sample)
  END
$$
LANGUAGE SQL
STABLE
CALLED ON NULL INPUT;

-- find the rate of change over time (per second), accounting for resets
-- usage: rate_time(value, lag(value) OVER w, '$__interval')
CREATE OR REPLACE FUNCTION rate_time(last_sample float, lag_sample float, time_range INTERVAL) RETURNS float
AS $$
  SELECT rate_diff(last_sample, lag_sample) / interval_seconds(time_range)
$$
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT;

-- usage: rate_time_smooth(value, lag(value) OVER w, lead(value) OVER w, '$__interval')
CREATE OR REPLACE FUNCTION rate_time_smooth(last_sample float, lag_sample float, lead_sample float, time_range INTERVAL) RETURNS float
AS $$
  SELECT rate_smooth(last_sample, lag_sample, lead_sample) / interval_seconds(time_range)
$$
LANGUAGE SQL
STABLE
CALLED ON NULL INPUT;