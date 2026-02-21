# Configuring Observability

Monitor and observe the operation of the PostgreSQL Operator using metrics.

## Metrics

Metrics configuration for the PostgreSQL Operator deployment is enabled by default using the Prometheus format. This package comes pre-configured with the necessary annotations to let Prometheus scrape metrics automatically from all its components.

If you'd like to remove the Prometheus annotations and therefore disable automatic scraping of PostgreSQL Operator metrics, you can apply the following configuration:

```yaml
prometheus:
  enabled: false
```

For more information, check the CloudNativePG documentation for [metrics](https://cloudnative-pg.io/docs/1.28/monitoring).
