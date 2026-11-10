# Security

See the [CloudNativePG security documentation](https://cloudnative-pg.io/docs/1.30/security) for the security model of the operator and of the PostgreSQL clusters.

## Pod Security Standards

The operator complies with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on the package namespace. With their default security contexts, the PostgreSQL instances comply with it too, so it can be enforced on the namespaces of the Clusters. A Cluster can override them via `spec.podSecurityContext` and `spec.securityContext`, so Pod Security Admission, not the operator, is the boundary. See [Kubernetes admission control](https://cloudnative-pg.io/docs/1.30/security#kubernetes-admission-control).

## Permissions

The operator runs with the `cnpg-manager` ServiceAccount, bound to the `cnpg-manager` ClusterRole, since it manages the PostgreSQL clusters in all namespaces. See [RBAC](https://cloudnative-pg.io/docs/1.30/security#role-based-access-control-rbac).

Anyone who can create or update a Cluster can set any field of its Pods, so grant write access to the CloudNativePG resources only to trusted users. See [trust model](https://cloudnative-pg.io/docs/1.30/security#trust-model-and-security-boundaries).

The package includes the upstream ClusterRoles to grant users access to the `Database`, `Publication`, and `Subscription` resources: `cnpg-database-editor-role`, `cnpg-database-viewer-role`, and the corresponding ones for publications and subscriptions. Bind them to the users that need them.

## Private registries

The `canonical-registry-credentials` Secret in the package namespace holds the credentials to pull the images from a private registry. It's populated by [secretgen-controller](https://github.com/carvel-dev/secretgen-controller) from a Secret exported to the package namespace, and used to pull the operator image.

The PostgreSQL instances bootstrap with the operator image too, in their `bootstrap-controller` init container. When a Cluster is created, the operator copies the Secret to its namespace, as `<cluster>-pull`, and adds it to the ServiceAccount of the Cluster, so that all its Pods can pull from the private registry. The copy isn't updated afterwards: create the Clusters after secretgen-controller populated the Secret, and recreate `<cluster>-pull` when the credentials change.

Upstream, the operator copies the `cnpg-pull-secret` Secret instead. To use a different Secret, set the `PULL_SECRET_NAME` option (see [configuration.md](configuration.md#operator-configuration)).

The PostgreSQL and PgBouncer images aren't part of the package. In air-gapped environments, relocate them separately and reference them from the Clusters and Poolers, from an [image catalog](https://cloudnative-pg.io/docs/1.30/image_catalog), or via the `POSTGRES_IMAGE_NAME` and `PGBOUNCER_IMAGE_NAME` options. The official image catalogs reference the images by digest.

## Admission webhooks

The operator serves the admission webhooks that default and validate the CloudNativePG resources, on port 9443. It generates their certificate, stored in the `cnpg-webhook-cert` Secret with its CA in `cnpg-ca-secret`, and injects the CA into the webhook configurations. The package keeps the injected CA when it's reconciled. If the CA is injected by cert-manager instead, set the `MANAGE_WEBHOOK_CONFIGURATIONS` option to `false`.

On some managed Kubernetes services, like private GKE clusters, a firewall blocks the traffic from the control plane to the nodes, except for a few ports. If creating a Cluster fails with `failed calling webhook`, open port 9443 in the firewall. See [installation](https://cloudnative-pg.io/docs/1.30/installation_upgrade#directly-using-the-operator-manifest).

## Network policies

The package doesn't include network policies. If you add some, allow:

* the inbound traffic from the Kubernetes API server to the operator on port 9443 (admission webhooks), and from Prometheus on port 8080 (metrics);
* the outbound traffic from the operator to the Kubernetes API server, and to the PostgreSQL instances on port 8000 (status, with the sensitive endpoints authenticated via the operator client certificate).

See [exposed ports](https://cloudnative-pg.io/docs/1.30/security#exposed-ports) and [networking](https://cloudnative-pg.io/docs/1.30/networking).

## Image verification

The CloudNativePG images are signed with [Cosign keyless signatures](https://cloudnative-pg.io/docs/1.30/security#image-signatures) by the release workflows on GitHub Actions.

```shell
cosign verify ghcr.io/cloudnative-pg/cloudnative-pg:1.30.1 \
  --certificate-identity-regexp="^https://github.com/cloudnative-pg/cloudnative-pg/.github/workflows/release-publish.yml@refs/tags/v" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

The package itself is signed too. See [verify-release.md](verify-release.md).
