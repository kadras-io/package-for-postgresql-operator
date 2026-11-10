# High Availability

## Operator

The package runs 1 replica of the operator, which is enough for most installations: the PostgreSQL instances keep running and serving traffic while the operator is unavailable, and the operator reconciles them again when it's back. However, the admission webhooks served by the operator reject the changes to the CloudNativePG resources while no replica is available.

The operator runs with leader election: additional replicas are standby, and all of them serve the admission webhooks. With more than one replica, a PodDisruptionBudget keeps at least one available during node drains.

```yaml
replicas: 2
```

To keep the operator off the nodes running the PostgreSQL instances, see [configuration.md](configuration.md#node-placement).

## PostgreSQL clusters

The high availability of the PostgreSQL clusters is configured in each Cluster, with the number of instances, their affinity, and the synchronous replication. The operator creates two PodDisruptionBudgets for each Cluster: before a node drain, it switches the primary over to a replica, and it blocks the drain of the node running a single-instance Cluster. See [replication](https://cloudnative-pg.io/docs/1.30/replication), [scheduling](https://cloudnative-pg.io/docs/1.30/scheduling), and [Kubernetes upgrade and maintenance](https://cloudnative-pg.io/docs/1.30/kubernetes_upgrade).

## Operator upgrades

After an operator upgrade, the PostgreSQL clusters are rolled out to update the instance manager, which ends with a restart or a switchover of the primary. See [upgrade.md](upgrade.md) to spread the rollouts over time, or to avoid them with in-place updates.
