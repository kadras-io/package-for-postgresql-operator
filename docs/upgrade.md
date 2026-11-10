# Upgrading

Read the [release notes](https://cloudnative-pg.io/docs/1.30/release_notes) of each CloudNativePG version before upgrading, since some versions require extra steps. CloudNativePG recommends upgrading through each version in sequential order, without skipping any.

```shell
kctrl package installed update -i postgresql-operator -v ${VERSION} -n kadras-system
```

Upgrading the operator also updates the instance manager running in each PostgreSQL instance. By default, every PostgreSQL cluster is rolled out: the replicas one at a time, then the primary, which is restarted or switched over depending on the `primaryUpdateMethod` of the Cluster. Either way, the applications must reconnect. With `primaryUpdateStrategy: supervised` in a Cluster, the update of the primary waits for a manual switchover. See [upgrades](https://cloudnative-pg.io/docs/1.30/installation_upgrade#upgrades) and [rolling updates](https://cloudnative-pg.io/docs/1.30/rolling_update).

## Spread upgrades

By default, all the PostgreSQL clusters are rolled out at the same time. To spread the load, wait between the rollouts of different clusters, and between the instances of the same cluster:

```yaml
upgrades:
  clusters_rollout_delay: 60
  instances_rollout_delay: 10
```

## In-place updates

The instance manager can be updated in place instead, without restarting PostgreSQL. The Pods then don't reflect the operator version in their definition anymore, since their init container keeps the previous operator image.

```yaml
upgrades:
  in_place_updates: true
```

See [in-place updates of the instance manager](https://cloudnative-pg.io/docs/1.30/installation_upgrade#in-place-updates-of-the-instance-manager).

## Uninstalling

The PersistentVolumeClaims of the PostgreSQL instances are owned by their Cluster: deleting a Cluster deletes all its data. Deleting the CloudNativePG CRDs would delete all the Clusters. Uninstalling the package doesn't delete them: it keeps the CRDs and the operator namespace, and only deletes the operator and its webhooks. The PostgreSQL instances keep running without the operator, so without failover. Installing the package again resumes the reconciliation.

To remove everything, delete the CloudNativePG resources before uninstalling the package, while the operator still runs, then delete the CRDs and the namespace.

```shell
kubectl delete clusters.postgresql.cnpg.io --all -A
kctrl package installed delete -i postgresql-operator -n kadras-system
kubectl get crds -o name | grep '\.postgresql\.cnpg\.io$' | xargs kubectl delete
kubectl delete namespace cnpg-system
```
