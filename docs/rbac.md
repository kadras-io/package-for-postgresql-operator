# Access to the Resources

The package extends the Kubernetes [default roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) with the CloudNativePG resources, via [aggregation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles). The users bound to `admin`, `edit`, or `view` in a namespace get the following permissions on the resources in that namespace.

| Resources | `admin`, `edit` | `view` |
|-----------|-----------------|--------|
| Cluster, Database, DatabaseRole, Pooler, ImageCatalog | Read and write | Read |
| Backup, ScheduledBackup | Read and write | Read |
| Publication, Subscription | Read and write | Read |
| FailoverQuorum | Read | Read |

The FailoverQuorums are managed by the operator. The ClusterImageCatalogs are cluster-scoped, so they're managed by the cluster administrators.

The permissions are granted by the `postgresql-operator-edit` and `postgresql-operator-view` ClusterRoles. The Secrets generated for the PostgreSQL clusters, like the credentials of the application user, follow the Kubernetes default roles: `edit` and `admin` can read them, `view` can't.
