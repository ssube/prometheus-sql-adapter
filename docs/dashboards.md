# Dashboards

## How To Use

### Release Annotations

### Variables

**Note:** variables cannot be used with alerts. Combining the two would require a mapping of variable
values to their appropriate thresholds and, combined with repeated panels, could cause an explosion of
alert queries on the backend.

## Best Practices

- export and commit dashboards often
- limit the number of panels per dashboard to 8-12
  - each panel is a JSON request and browsers will only make 6-8 requests per hostname. Large dashboards
    will spin as panels wait to load, and slow panels may block faster ones.
  - with 12 panels and a 30 second query timeout, dashboards should take no longer than 60 seconds to load.
