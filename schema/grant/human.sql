-- grant/grafana should also be run for this role
\i schema/grant/grafana.sql

GRANT SELECT ON metric_samples TO :role_name;

-- grafana sets a 60s timeout, decrease that
ALTER ROLE :role_name SET statement_timeout=:timeout_human;