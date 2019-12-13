# Schema

## Contents

- [Schema](#schema)
  - [Contents](#contents)
  - [Paths](#paths)
  - [Style](#style)

## Paths

- [alert](./alert): alerting queries
- [cagg](./cagg): continuous aggregate views
  - container
  - instance
- [catalog](./catalog): materialized catalog views
- [grant](./grant): role profiles
- [history](./history): historical queries
- [issue](./issue): github issue fix/plan/repro queries
- [meta](./meta): schema metadata queries
- [misc](./misc): unsorted queries
- [utils](./utils): utility functions

## Style

```sql
-- table description
CREATE TABLE IF NOT EXISTS table_name (
  "column_name" TYPE NOT NULL,          -- column description
  "next_column" TYPE
);

CREATE INDEX IF NOT EXISTS table_name_column1_column2
ON table_name
USING GIN (
  column_name,
  next_column
)
WHERE
  next_column = 'some literal';

SELECT
  column_name,
  next_column
FROM table_name AS t
GROUP BY column_name
WINDOW w AS (
  PARTITION BY metric,
  ORDER BY time
)
ORDER BY time
```

- alias:
  - all tables in a join or none of them
  - `AS foo`
- keywords:
  - at the beginning of their line
  - capitalized
- misc:
  - indentation levels are two spaces each
- parentheses:
  - open at the end of a line
  - close at the beginning
  - indent their contents
- time:
  - time groups are buckets: `time_bucket(time, interval) AS bucket`
