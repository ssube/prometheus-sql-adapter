FROM golang:1.13 AS build

ENV GOPATH=/go
COPY . /go/src/github.com/ssube/prometheus-sql-adapter
WORKDIR /go/src/github.com/ssube/prometheus-sql-adapter
RUN go build .

FROM postgres:10 AS run

COPY --from=build /go/src/github.com/ssube/prometheus-sql-adapter/prometheus-sql-adapter /app/prometheus-sql-adapter

ENTRYPOINT [ "/app/prometheus-sql-adapter" ]
