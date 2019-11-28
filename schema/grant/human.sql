ALTER ROLE :role_name SET statement_timeout=30000;

GRANT SELECT ON metric_samples TO :role_name;

-- grant/grafana should also be run for this role
\i schema/grant/grafana.sql