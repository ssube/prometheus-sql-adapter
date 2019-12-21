# Kubernetes Deploy

To deploy TimescaleDB and this SQL adapter:

- create a namespace: `k create ns test-schema`
- apply node labels
  - for server nodes: `k label node/server timescale-role=server`
  - for adapter nodes: `k label node/adapter timescale-role=adapter`
- apply the server: `k apply -n test-schema -f kubernetes/server.yml`
- create an adapter role ([getting started](../README.md#getting-started))
  - `k exec -n test-schema -it timescale-server-0 -- psql -U postgres`
  - `CREATE USER prometheus_adapter WITH LOGIN PASSWORD 'very-secret';`
  - `k exec -n test-schema -it timescale-server-0 -- sh -c 'cd /app; PGUSER=postgres PGDATABASE=prometheus /app/scripts/schema-grant.sh prometheus_adapter adapter'`
- create a secret with PG connection info:
  `k create secret generic timescale-adapter-env -n test-schema --from-literal=PGUSER=prometheus_adapter --from-literal=PGPASSWORD=very-secret --from-literal=PGDATABASE=prometheus`
- apply the adapter: `k apply -n foo -f kubernetes/adapter.yml`

The server and two adapter pods should be `Running`:

```shell
> kubectl -n foo get pods

NAME                                 READY   STATUS    RESTARTS   AGE
timescale-adapter-5dbfbd4586-hvgbz   1/1     Running   0          55s
timescale-adapter-5dbfbd4586-tm2rj   1/1     Running   0          32s
timescale-server-0                   1/1     Running   0          9m3s
```

If they are not, `k -n foo describe pod` should have more information. The adapter have anti-affinity with one
another and will not be placed on the same node. Database info and errors will appear in the adapter pod's logs:

```shell
> kubectl -n test-schema logs timescale-adapter-579f68b6ff-g5k64
level=info ts=2019-11-28T19:34:12.447Z caller=main.go:109 msg="Allowed metric names" names=16
level=info ts=2019-11-28T19:34:12.447Z caller=main.go:169 msg="Starting postgres..." conn="postgres://timescale-server?sslmode=disable"
level=info ts=2019-11-28T19:34:12.447Z caller=client.go:143 storage=postgres msg="connecting to database" idle=8 open=8
level=info ts=2019-11-28T19:34:12.447Z caller=client.go:153 storage=postgres msg="creating cache" size=65535
level=info ts=2019-11-28T19:34:12.447Z caller=main.go:179 msg="Starting up..."
```

## Notes

- The server sets up the `prometheus` database and metrics schema within that when it starts up.
- The server pod does not have persistent storage, so any data will be lost when it restarts.
- The `--pg.conn-str` parameter will be printed in the logs, please put the password in the `PGPASSWORD` env var.
