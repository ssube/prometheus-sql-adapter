# Schema Style

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
  - time groups:
    - are called buckets: `time_bucket(time, interval) AS bucket`
    - must use `time_bucket` in caggs
- grafana:
  - must use the `$__timeGroup(...)` macro
  - macros/variables:
    - must use `${name}` or `[[name]]` forms (work correctly mid-word and allowed escaping)
    - must not use `$name` or `$__name` forms (do not work mid-word)
