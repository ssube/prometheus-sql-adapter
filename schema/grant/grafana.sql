ALTER ROLE :role_name SET statement_timeout=:timeout_robot;

GRANT SELECT ON metric_labels TO :role_name;
GRANT SELECT ON metrics TO :role_name;
-- metric_samples is intentionally omitted to prevent
-- grafana from accidentally pulling raw samples and
-- crashing when it runs out of memory

GRANT SELECT ON agg_instance_load TO :role_name;
GRANT SELECT ON agg_instance_load_long TO :role_name;
GRANT SELECT ON agg_instance_pods TO :role_name;

GRANT SELECT ON agg_container_cpu TO :role_name;
GRANT SELECT ON agg_container_mem TO :role_name;

GRANT SELECT ON catalog_container TO :role_name;
GRANT SELECT ON catalog_instance TO :role_name;
GRANT SELECT ON catalog_name TO :role_name;