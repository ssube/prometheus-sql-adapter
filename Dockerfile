FROM ubuntu

ADD prometheus-sql-adapter /app/prometheus-sql-adapter

ENTRYPOINT [ "/app/prometheus-sql-adapter" ]
