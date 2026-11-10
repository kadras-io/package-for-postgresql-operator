# Configuration

The package values cover the decisions most installations need to make: the operator namespace and replicas, the labels and annotations inherited from the Clusters, the rollout after an upgrade, and observability. Everything else can still be customized in three ways.

## Operator configuration

The operator reads its configuration from the `cnpg-controller-manager-config` ConfigMap in its namespace, at startup. The package computes some options from the values, then merges `config` on top, so its options take precedence. An option set to `null` is removed. When the configuration changes, the operator is rolled out to load it. The changes only apply to the Clusters created afterwards.

```yaml
config:
  POSTGRES_IMAGE_NAME: ghcr.io/cloudnative-pg/postgresql:18.6-system-trixie
  KUBERNETES_CLUSTER_DOMAIN: example.local
  CREATE_ANY_SERVICE: true
```

The available options are listed in the [operator configuration](https://cloudnative-pg.io/docs/1.30/operator_conf#available-options). The ones computed by the package are:

| Option | Value |
|--------|-------|
| `PULL_SECRET_NAME` | `canonical-registry-credentials`, see [security.md](security.md#private-registries) |
| `CLUSTERS_ROLLOUT_DELAY` | `upgrades.clusters_rollout_delay` |
| `INSTANCES_ROLLOUT_DELAY` | `upgrades.instances_rollout_delay` |
| `ENABLE_INSTANCE_MANAGER_INPLACE_UPDATES` | `upgrades.in_place_updates` |
| `INHERITED_ANNOTATIONS` | `inherited_annotations`, comma-separated |
| `INHERITED_LABELS` | `inherited_labels`, comma-separated |

The operator also reads a Secret with the same name, if it exists, whose options take precedence over the ConfigMap. Use it for sensitive options, created separately from the package.

### Inherited labels and annotations

The labels and annotations listed in `inherited_labels` and `inherited_annotations`, when set on a Cluster, are copied to all the resources generated for it, including the Pods, the Services, and the PersistentVolumeClaims. Wildcards like `example.com/*` are supported.

```yaml
inherited_labels:
  - app.kubernetes.io/part-of
  - environment
inherited_annotations:
  - example.com/*
```

## Container flags

The operator is configured via container flags too. The package computes the log level from the values and merges it into the upstream flags, then merges `args` on top, so its flags take precedence. The flags are written without the leading dashes, and a flag set to `null` is removed. The upstream `controller` subcommand is always kept.

```yaml
args:
  max-concurrent-reconciles: 20
  log-field-level: severity
  log-field-timestamp: timestamp
```

An unknown flag prevents the operator from starting. Check the [operator configuration](https://cloudnative-pg.io/docs/1.30/operator_conf) of the CloudNativePG version you install before adding one. A change rolls out the operator.

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic postgresql-operator-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall postgresql-operator -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=postgresql-operator-overlays
```

The operator runs in the `cnpg-controller-manager` Deployment, in a container named `manager`.

### Resources

The upstream manifest requests 100m CPU and 100Mi memory, with a 200Mi memory limit, which can be too little when managing many Clusters.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "cnpg-controller-manager"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: manager
          resources:
            limits:
              cpu: 500m
              memory: 512Mi
            requests:
              cpu: 200m
              memory: 256Mi
```

### Node placement

Keep the operator off the nodes running the PostgreSQL instances, so that a node failure doesn't take down both.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "cnpg-controller-manager"}})
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      nodeSelector:
        node-restriction.kubernetes.io/reserved-for: platform
      #@overlay/match missing_ok=True
      tolerations:
        - key: node-restriction.kubernetes.io/reserved-for
          operator: Equal
          value: platform
          effect: NoExecute
```
