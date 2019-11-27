-- grant/grafana should also be run for this role
\i schema/grant/grafana.sql

ALTER ROLE :role_name SET statement_timeout=30000;