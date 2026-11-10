# Observability

## Logs

The operator writes its logs in JSON format. The log level is one of `error`, `warn`, `info`, `debug`, `trace`.

```yaml
observability:
  logging:
    level: info
```

If your log ingestion system requires different names for the level and timestamp fields, set them via flags (see [configuration.md](configuration.md#container-flags)).

```yaml
args:
  log-field-level: severity
  log-field-timestamp: timestamp
```

To read the operator logs:

```shell
kubectl logs -n cnpg-system deployment/cnpg-controller-manager
```

The log level of the PostgreSQL instances is set in each Cluster, via `spec.logLevel`, and applies to the Pods created afterwards. The PostgreSQL logs are written in JSON format to the standard output of the instances. See [logging](https://cloudnative-pg.io/docs/1.30/logging).

## Metrics

The operator exposes metrics in the Prometheus format on port 8080 (`/metrics`), on the `metrics` container port. Its Pods are annotated for Prometheus scraping (`prometheus.io/scrape`, `prometheus.io/port`, `prometheus.io/path`). To remove the annotations:

```yaml
observability:
  metrics:
    enabled: false
```

If you use the Prometheus Operator, create a PodMonitor instead:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: cnpg-controller-manager
  namespace: cnpg-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: cloudnative-pg
  podMetricsEndpoints:
    - port: metrics
```

The metrics endpoint is served over HTTP. To serve it over TLS, mount a certificate in the operator Pod with a ytt overlay and set the `METRICS_CERT_DIR` option (see [configuration.md](configuration.md#operator-configuration)). See [enabling TLS for operator metrics](https://cloudnative-pg.io/docs/1.30/monitoring#enabling-tls-for-operator-metrics).

The PostgreSQL instances expose their own metrics on port 9187, including the ones from the default monitoring queries in the `cnpg-default-monitoring` ConfigMap. Create a PodMonitor for each Cluster, selecting its Pods via the `cnpg.io/cluster` label. See [monitoring](https://cloudnative-pg.io/docs/1.30/monitoring) and the [Grafana dashboard](https://github.com/cloudnative-pg/grafana-dashboards).
