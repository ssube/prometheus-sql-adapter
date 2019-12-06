# Schema

## Contents

- [Schema](#schema)
  - [Contents](#contents)
  - [Paths](#paths)
  - [Style](#style)

## Paths

- cagg: continous aggregate views
  - container
  - instance
- grant: role profiles
- query:
  - alert: short-term queries
  - history: long-term queries
  - issue: queries developed to test specific Github issues
  - schema: metadata queries

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

- keywords:
  - at the beginning of their line
  - capitalized
- parentheses:
  - open at the end of a line
  - close at the beginning
  - indent their contents
- indentation levels are two spaces each
- when more than one table is involved:
  - alias all or none of them
