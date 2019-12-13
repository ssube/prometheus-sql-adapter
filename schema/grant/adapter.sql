GRANT ALL ON metric_labels TO :role_name;
GRANT ALL ON metric_samples TO :role_name;
GRANT ALL ON metrics TO :role_name;

GRANT ALL ON agg_instance_load TO :role_name;
GRANT ALL ON agg_instance_load_long TO :role_name;
GRANT ALL ON agg_instance_pods TO :role_name;

GRANT ALL ON agg_container_cpu TO :role_name;
GRANT ALL ON agg_container_mem TO :role_name;

GRANT ALL ON catalog_container TO :role_name;
GRANT ALL ON catalog_instance TO :role_name;
GRANT ALL ON catalog_name TO :role_name;