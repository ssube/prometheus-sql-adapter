echo "Prometheus SQL adapter - schema debug report"
echo "$(date)"
echo
echo

psql -f schema/meta/debug.sql
