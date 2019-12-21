package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	_ "net/http/pprof"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/gogo/protobuf/proto"
	"github.com/golang/snappy"
	"github.com/pkg/errors"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/common/model"
	"gopkg.in/alecthomas/kingpin.v2"

	"github.com/prometheus/common/promlog"
	"github.com/prometheus/common/promlog/flag"

	"github.com/prometheus/prometheus/prompb"

	"github.com/ssube/prometheus-sql-adapter/metric"
	"github.com/ssube/prometheus-sql-adapter/postgres"
)

type config struct {
	allowedNames  []string
	listenAddr    string
	Postgres      postgres.ClientConfig
	telemetryPath string
	promlogConfig promlog.Config
}

var (
	receivedSamples = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name:      "received_total",
			Namespace: "adapter",
			Subsystem: "samples",
			Help:      "Total number of received samples.",
		},
	)
	sentSamples = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "sent_total",
			Namespace: "adapter",
			Subsystem: "samples",
			Help:      "Total number of processed samples sent to remote storage.",
		},
		[]string{"remote"},
	)
	failedSamples = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name:      "failed_total",
			Namespace: "adapter",
			Subsystem: "samples",
			Help:      "Total number of processed samples which could not be sent to remote storage.",
		},
		[]string{"remote"},
	)
	sentBatchDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:      "sent_duration_seconds",
			Namespace: "adapter",
			Subsystem: "samples",
			Help:      "Duration of sample batch send calls to the remote storage.",
			Buckets:   prometheus.DefBuckets,
		},
		[]string{"remote"},
	)

	CIBuildJob       string
	CIBuildNode      string
	CIBuildRunner    string
	CIGitBranch      string
	CIGitCommit      string
	CIPackageName    string
	CIPackageVersion string
)

func init() {
	prometheus.MustRegister(receivedSamples)
	prometheus.MustRegister(sentSamples)
	prometheus.MustRegister(failedSamples)
	prometheus.MustRegister(sentBatchDuration)
}

func main() {
	cfg := parseFlags(os.Args)
	if cfg == nil {
		os.Exit(2)
	}

	logger := promlog.New(&cfg.promlogConfig)
	level.Info(logger).Log(
		"msg", "Starting SQL adapter",
		"build_job", CIBuildJob,
		"build_node", CIBuildNode,
		"build_runner", CIBuildRunner,
		"git_branch", CIGitBranch,
		"git_commit", CIGitCommit,
		"package_name", CIPackageName,
		"package_version", CIPackageVersion,
	)
	level.Info(logger).Log("msg", "Allowed metric names", "count", len(cfg.allowedNames), "allowed", strings.Join(cfg.allowedNames, ","))

	http.Handle(cfg.telemetryPath, promhttp.Handler())
	writers, readers := buildClients(logger, cfg)
	if err := serve(logger, cfg.listenAddr, writers, readers, cfg.allowedNames); err != nil {
		level.Error(logger).Log("msg", "Failed to listen", "addr", cfg.listenAddr, "err", err)
		os.Exit(1)
	}
}

func parseFlags(args []string) *config {
	a := kingpin.New(filepath.Base(args[0]), "Prometheus SQL adapter")
	a.HelpFlag.Short('h')

	cfg := &config{
		promlogConfig: promlog.Config{},
	}

	a.Flag("allow", "The allowed metric names.").
		Default("").StringsVar(&cfg.allowedNames)

	a.Flag("pg.cache-size", "The maximum label cache size.").
		Default("100000").IntVar(&cfg.Postgres.CacheSize)
	a.Flag("pg.conn-str", "The connection string for pq.").
		Default("").StringVar(&cfg.Postgres.ConnStr)
	a.Flag("pg.max-idle", "The max idle connections.").
		Default("0").IntVar(&cfg.Postgres.MaxIdle)
	a.Flag("pg.max-open", "The max open connections.").
		Default("8").IntVar(&cfg.Postgres.MaxOpen)
	a.Flag("pg.ping-cron", "The ping cron expression.").
		Default("@every 15s").StringVar(&cfg.Postgres.PingCron)
	a.Flag("pg.ping-timeout", "The ping timeout.").
		Default("5s").DurationVar(&cfg.Postgres.PingTimeout)
	a.Flag("pg.tx-isolation", "The transaction isolation level.").
		Default("Read Committed").StringVar(&cfg.Postgres.TxIsolation)

	a.Flag("web.listen-address", "Address to listen on for web endpoints.").
		Default(":9201").StringVar(&cfg.listenAddr)
	a.Flag("web.telemetry-path", "Address to listen on for web endpoints.").
		Default("/metrics").StringVar(&cfg.telemetryPath)

	flag.AddFlags(a, &cfg.promlogConfig)

	_, err := a.Parse(args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, errors.Wrapf(err, "error parsing commandline arguments"))
		return nil
	}

	return cfg
}

type writer interface {
	Write(metrics metric.Metrics, samples model.Samples) error
	Name() string
}

type reader interface {
	Read(req *prompb.ReadRequest) (*prompb.ReadResponse, error)
	Name() string
}

func buildClients(logger log.Logger, cfg *config) ([]writer, []reader) {
	var writers []writer
	var readers []reader
	if cfg.Postgres.ConnStr != "" {
		level.Info(logger).Log("msg", "Starting postgres...", "conn", cfg.Postgres.ConnStr)
		c := postgres.NewClient(log.With(logger, "remote", "postgres"), cfg.Postgres)
		if c != nil {
			writers = append(writers, c)
		} else {
			level.Error(logger).Log("msg", "Error starting client...")
		}
	}
	level.Info(logger).Log("msg", "Starting up...")
	return writers, readers
}

func serve(logger log.Logger, addr string, writers []writer, readers []reader, allowed []string) error {
	http.HandleFunc("/write", func(w http.ResponseWriter, r *http.Request) {
		compressed, err := ioutil.ReadAll(r.Body)
		if err != nil {
			level.Error(logger).Log("msg", "Read error", "err", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		reqBuf, err := snappy.Decode(nil, compressed)
		if err != nil {
			level.Error(logger).Log("msg", "Decode error", "err", err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		var req prompb.WriteRequest
		if err := proto.Unmarshal(reqBuf, &req); err != nil {
			level.Error(logger).Log("msg", "Unmarshal error", "err", err.Error())
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		metrics, samples := protoToSamples(&req, allowed)
		receivedSamples.Add(float64(len(samples)))

		var wg sync.WaitGroup
		for _, w := range writers {
			wg.Add(1)
			go func(rw writer) {
				sendSamples(logger, rw, metrics, samples)
				wg.Done()
			}(w)
		}
		wg.Wait()
	})

	return http.ListenAndServe(addr, nil)
}

func protoToSamples(req *prompb.WriteRequest, allowed []string) (metric.Metrics, model.Samples) {
	var metrics metric.Metrics
	var samples model.Samples
	for _, ts := range req.Timeseries {
		m := make(model.Metric, len(ts.Labels))
		for _, l := range ts.Labels {
			m[model.LabelName(l.Name)] = model.LabelValue(l.Value)
		}

		if metric.FilterMetric(&m, allowed) != true {
			continue
		}

		metrics = append(metrics, &m)

		for _, s := range ts.Samples {
			samples = append(samples, &model.Sample{
				Metric:    m,
				Value:     model.SampleValue(s.Value),
				Timestamp: model.Time(s.Timestamp),
			})
		}
	}
	return metrics, samples
}

func sendSamples(logger log.Logger, w writer, metrics metric.Metrics, samples model.Samples) {
	begin := time.Now()
	err := w.Write(metrics, samples)
	duration := time.Since(begin).Seconds()
	if err != nil {
		level.Warn(logger).Log("msg", "Error sending samples to remote storage", "err", err, "remote", w.Name(), "count", len(samples))
		failedSamples.WithLabelValues(w.Name()).Add(float64(len(samples)))
	}
	sentSamples.WithLabelValues(w.Name()).Add(float64(len(samples)))
	sentBatchDuration.WithLabelValues(w.Name()).Observe(duration)
}
