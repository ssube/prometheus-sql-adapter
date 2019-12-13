-- find the rate of change, accounting for resets
-- usage: rate_diff(value, lag(value) OVER w)
CREATE OR REPLACE FUNCTION rate_diff(a float, b float) RETURNS float
AS $$
  SELECT CASE
    WHEN a >= b THEN a - b      -- rising edge
    WHEN b IS NULL THEN NULL    -- leading gap
    ELSE a                      -- falling edge/reset
  END
$$
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT;

-- find the rate of change, accounting for leading resets and 0s (but requires both lag and lead rows)
-- using "Null value: connected" in Grafana has a similar effect without fetching an extra row
-- usage: rate_smooth(value, lag(value) OVER w, lead(value) OVER w)
CREATE OR REPLACE FUNCTION rate_smooth(a float, b float, c float) RETURNS float
AS $$
  SELECT CASE
    WHEN b IS NULL THEN rate_diff(c, a)
    ELSE rate_diff(a, b)
  END
$$
LANGUAGE SQL
STABLE
CALLED ON NULL INPUT;

-- find the rate of change over time (per second), accounting for resets
-- usage: rate_time(value, lag(value) OVER w, '$__interval')
CREATE OR REPLACE FUNCTION rate_time(a float, b float, t INTERVAL) RETURNS float
AS $$
  SELECT rate_diff(a, b) / interval_seconds(t)
$$
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT;

-- usage: rate_time_smooth(value, lag(value) OVER w, lead(value) OVER w, '$__interval')
CREATE OR REPLACE FUNCTION rate_time_smooth(a float, b float, c float, t INTERVAL) RETURNS float
AS $$
  SELECT rate_smooth(a, b, c) / interval_seconds(t)
$$
LANGUAGE SQL
STABLE
CALLED ON NULL INPUT;