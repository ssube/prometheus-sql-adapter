# Kubernetes Deploy

To deploy TimescaleDB and this SQL adapter:

- create a namespace: `k create ns foo`
- apply node labels
  - for server nodes: `k label node/bar timescale-role=server`
  - for adapter nodes: `k label node/baz timescale-role=adapter`
- apply the server: `k apply -n foo -f kubernetes/server.yml`
- [get started](../README.md#getting-started)
  - you may need to forward a port to the server: `k -n foo port-forward svc/timescale-server 5432:5432`
  - apply the schema: `PGHOST=localhost PGUSER=your-name PGPASSWORD=very-secret ./scripts/schema-create.sh`
  - create an adapter role
- create a secret with PG connection info:
  `k create secret generic prometheus-adapter-env -n foo --from-literal=PGUSER=adapter --from-literal=PGPASSWORD=very-secret --from-literal=PGDATABASE=bar`
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

The `--pg.conn-str` parameter will be printed in the logs, please put the password in the `PGPASSWORD` env var.
