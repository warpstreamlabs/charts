# WarpStream Self-Hosted Control Plane

[WarpStream](https://www.warpstream.com/) is an Apache Kafka® compatible data streaming platform built directly on top of object storage. This Helm chart deploys the WarpStream self-hosted control plane into your Kubernetes cluster. The control plane stores cluster metadata in your own AWS account, and your WarpStream agents connect to it instead of WarpStream Cloud. This chart currently supports AWS with DynamoDB as the metadata store.

## Using the WarpStream Helm Repository

Start by adding this repository to your Helm repositories:

```shell
helm repo add warpstream https://warpstreamlabs.github.io/charts
helm repo update
```


## Prerequisites

Helm v3.6 or later.

You also need:
- An EKS cluster with at least 3 nodes, ideally spread across 3 availability zones. The control plane always runs at least 3 replicas.
- An S3 bucket for metadata snapshots.
- An IAM role the control plane pods can assume (IRSA or EKS Pod Identity) with access to DynamoDB and the bucket. See [AWS Permissions](#aws-permissions).
- The enterprise license key, image repository and release version provided by WarpStream.


## Quickstart

By default, the control plane runs 3 replicas behind a ClusterIP Service. Additional steps are required to grant the pods permission to access DynamoDB and object storage, see [Deployment Considerations](#deployment-considerations).

### Installing the WarpStream Self-Hosted Control Plane Chart

Create a Kubernetes Secret for the license key:

```shell
kubectl create secret generic warpstream-license \
    --namespace $YOUR_NAMESPACE \
    --from-literal=license-key="$YOUR_LICENSE_KEY"
```

1. Create an empty `warpstream-values.yaml` file
2. Edit the file with your specific parameters:

```yaml
image:
  repository: <WARPSTREAM_IMAGE_REPOSITORY>
  tag: <WARPSTREAM_RELEASE_VERSION>

config:
  snapshotBucketURL: <WARPSTREAM_SNAPSHOT_BUCKET_URL>
  clusterConf: |
    <WARPSTREAM_CONFIGURATION_FILE>

license:
  existingSecret: warpstream-license

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: <WARPSTREAM_CONTROL_PLANE_ROLE_ARN>
```

See [Configuration File](#configuration-file) for the contents of `config.clusterConf`. The chart creates a Kubernetes Secret for it. You can also create a secret manually and set `config.existingSecret` and `config.existingSecretKey` to the name of your Kubernetes secret and the data key name within that secret. The same applies to the license key with `license.key`, `license.existingSecret` and `license.existingSecretKey`.

3. Install or upgrade the chart using your custom YAML file:

```shell
helm upgrade --install warpstream-control-plane warpstream/warpstream-self-hosted-control-plane \
    --namespace $YOUR_NAMESPACE \
    -f warpstream-values.yaml
```

### Verifying the Installation

Check that all replicas are ready and running the release you deployed. The startup log line includes the release version:

```shell
kubectl rollout status deployment/warpstream-control-plane-warpstream-self-hosted-control-plane --namespace $YOUR_NAMESPACE
kubectl logs deployment/warpstream-control-plane-warpstream-self-hosted-control-plane --namespace $YOUR_NAMESPACE | grep "service startup complete"
```

For about the first minute after the control plane starts, its logs include errors such as `statistics not yet loaded` and agents may get `500` or `503` responses while the replicas elect a leader and load their metadata. They clear on their own.

Once your agents are deployed (see [Connecting Agents](#connecting-agents)), check that they can serve Kafka traffic, and that the agent chart's dedicated metrics pod logs `successfully published metrics`:

```shell
kubectl exec deployment/warpstream-agent --namespace $YOUR_NAMESPACE -- /warpstream cli diagnose-connection
```

### Upgrading

To upgrade to a new control plane release:

```shell
helm repo update
helm upgrade warpstream-control-plane warpstream/warpstream-self-hosted-control-plane \
    --namespace $YOUR_NAMESPACE \
    --reuse-values \
    --set image.tag="$YOUR_NEW_RELEASE_VERSION"
```

When upgrading:
- Upgrade one release at a time, and keep at least 3 replicas running.
- The rollout replaces one replica at a time and waits `minReadySeconds` (2 minutes by default) after each, so 3 replicas take about 10 minutes.
- After the new release has rolled out, the control plane upgrades its metadata store in the background.
- Upgrade your agents to the version WarpStream recommends for the new release.

### Uninstalling the Chart

To uninstall/delete the deployment:

```shell
helm uninstall warpstream-control-plane --namespace $YOUR_NAMESPACE
```

This doesn't delete the DynamoDB tables or the snapshots in your bucket. The control plane creates its `rsm_logs`, `rsm_logs_chunks` and `rsm_snapshots` tables with deletion protection enabled, so to delete them, first turn it off:

```shell
aws dynamodb update-table --table-name rsm_logs_<WARPSTREAM_CLUSTER_NAME> --no-deletion-protection-enabled
```


## Deployment Considerations

Before installing, consider:
- **Metadata Storage**: Where will the control plane store its metadata?
- **Network Access**: Can the control plane pods reach DynamoDB, S3 and STS?
- **AWS Permissions**: How will your pods authenticate requests to DynamoDB and S3?
- **Configuration**: Which virtual clusters, agent keys and SASL credentials will the control plane serve?
- **Agents**: How will your agents reach the control plane?

### Metadata Storage

The control plane stores metadata snapshots in S3 and its metadata store in DynamoDB.

Create an S3 bucket (or use a prefix of an existing one) for metadata snapshots, and enable versioning so snapshots can be recovered. Set `config.snapshotBucketURL`, for example `s3://my-bucket?region=us-east-1&prefix=warpstream-control-plane/snapshots/`.

The control plane creates its own DynamoDB tables on first start, named after `warpstream_cluster_name` in the [configuration file](#configuration-file):
- `rsm_logs_<warpstream_cluster_name>`
- `rsm_logs_chunks_<warpstream_cluster_name>`
- `rsm_snapshots_<warpstream_cluster_name>`
- `locks_<warpstream_cluster_name>`

We recommend enabling point-in-time recovery on them once they exist.

### Network Access

The control plane makes no outbound calls other than to AWS. From private subnets, the control plane pods need a route to these services, through a NAT gateway or VPC endpoints:
- **DynamoDB** and **S3**: gateway endpoints.
- **STS**, for IRSA or EKS Pod Identity credentials: an interface endpoint for `sts`.

### AWS Permissions

Create an IAM role for the control plane service account and set its ARN with `serviceAccount.annotations."eks\.amazonaws\.com/role-arn"` (IRSA), or associate it with the service account using EKS Pod Identity. The service account is named `<release name>-warpstream-self-hosted-control-plane` (or `fullnameOverride`, or `serviceAccount.name` if set), so an IRSA trust policy should allow `system:serviceaccount:<namespace>:<service account name>`. Replace `<WARPSTREAM_CLUSTER_NAME>` with `warpstream_cluster_name`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeLimits",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:List*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGet*",
        "dynamodb:BatchWrite*",
        "dynamodb:CreateTable",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeStream",
        "dynamodb:DescribeTable",
        "dynamodb:Get*",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:TagResource",
        "dynamodb:Update*"
      ],
      "Resource": [
        "arn:aws:dynamodb:<AWS_REGION>:<AWS_ACCOUNT_ID>:table/rsm_logs_<WARPSTREAM_CLUSTER_NAME>",
        "arn:aws:dynamodb:<AWS_REGION>:<AWS_ACCOUNT_ID>:table/rsm_logs_chunks_<WARPSTREAM_CLUSTER_NAME>",
        "arn:aws:dynamodb:<AWS_REGION>:<AWS_ACCOUNT_ID>:table/rsm_snapshots_<WARPSTREAM_CLUSTER_NAME>",
        "arn:aws:dynamodb:<AWS_REGION>:<AWS_ACCOUNT_ID>:table/locks_<WARPSTREAM_CLUSTER_NAME>"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::<SNAPSHOT_BUCKET>/<SNAPSHOT_PREFIX>*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::<SNAPSHOT_BUCKET>"
    }
  ]
}
```

### Configuration File

The control plane reads its virtual clusters, agent keys and SASL credentials from a TOML file, set with `config.clusterConf` or an existing Secret (`config.existingSecret`). The file is only read at startup. The chart restarts the pods when `config.clusterConf` changes; with `config.existingSecret`, run `kubectl rollout restart deployment/warpstream-control-plane-warpstream-self-hosted-control-plane` after changing the secret.

The `${...}` values in this example are filled from environment variables, see [Keeping Secrets Out of the Configuration File](#keeping-secrets-out-of-the-configuration-file).

```toml
version = 2

# Names the DynamoDB tables. Don't change it after the first deployment.
warpstream_cluster_name = "my_control_plane"
cloud_provider = "aws"
region = "us-east-1"

[observability]
disable_logs_forwarding = true

[[virtual_clusters]]
# vci_ followed by a UUID with dashes replaced by underscores. Generate it once and never change it.
id = "vci_0f1c2d3e_4a5b_4c6d_8e7f_9a0b1c2d3e4f"
# vcn_ followed by a name of your choice.
name = "vcn_orders"
# Keep the metadata store on the newest version this release supports.
target_state_machine_version_max = true

# SASL credentials Kafka clients use for this virtual cluster.
[[virtual_clusters.sasl_credentials]]
username = "orders-app"
password = "${ORDERS_APP_PASSWORD}"
is_superuser = false

# Agent keys. Agents authenticate to the control plane with one of these.
[[api_keys]]
# aks_ followed by a random secret, e.g. aks_$(openssl rand -hex 32).
key = "${AGENT_KEY}"
# akn_ followed by a name of your choice.
name = "akn_agents"
```

| Key | Type | Description |
|-----|------|-------------|
| version | number | Must be `2` |
| warpstream_cluster_name | string | Name of this control plane. The DynamoDB table names are derived from it |
| cloud_provider | string | `aws` |
| region | string | AWS region of the DynamoDB tables |
| observability.disable_logs_forwarding | bool | Disables forwarding control plane logs to WarpStream |
| virtual_clusters[].id | string | `vci_<uuid with underscores>`. Must stay the same for the life of the cluster |
| virtual_clusters[].name | string | `vcn_<name>` |
| virtual_clusters[].target_state_machine_version_max | bool | Keeps the virtual cluster on the newest metadata version the release supports. Recommended |
| virtual_clusters[].acls_enabled | bool | Enforces Kafka ACLs on the virtual cluster. See [Kafka ACLs](#kafka-acls) |
| virtual_clusters[].acl_shadowing_enabled | bool | Logs what ACLs would deny without enforcing them. See [Kafka ACLs](#kafka-acls) |
| virtual_clusters[].external_superusers | list | Superusers that don't authenticate with SASL credentials, such as mTLS certificates. See [Superusers Without SASL Credentials](#superusers-without-sasl-credentials) |
| virtual_clusters[].sasl_credentials[] | list | `username`, `password` and `is_superuser` for Kafka SASL/PLAIN clients. Usernames must be unique across all virtual clusters |
| api_keys[].key | string | `aks_<secret>`. Agent key |
| api_keys[].name | string | `akn_<name>` |

Only set other fields, such as `feature_flags`, rate limits or `state_machine_config`, when WarpStream asks you to.

#### Multiple Virtual Clusters

Add a `[[virtual_clusters]]` entry per virtual cluster. A `[[virtual_clusters.sasl_credentials]]` entry belongs to the `[[virtual_clusters]]` entry above it, so put each virtual cluster's options directly under its `[[virtual_clusters]]` line, before its SASL credentials. An option placed after a `[[virtual_clusters.sasl_credentials]]` entry belongs to that credential instead.

```toml
[[virtual_clusters]]
id = "vci_0f1c2d3e_4a5b_4c6d_8e7f_9a0b1c2d3e4f"
name = "vcn_orders"
target_state_machine_version_max = true

[[virtual_clusters.sasl_credentials]]
username = "orders-app"
password = "${ORDERS_APP_PASSWORD}"

[[virtual_clusters]]
id = "vci_5a6b7c8d_9e0f_4a1b_8c2d_3e4f5a6b7c8d"
name = "vcn_payments"
target_state_machine_version_max = true

[[virtual_clusters.sasl_credentials]]
username = "payments-app"
password = "${PAYMENTS_APP_PASSWORD}"
```

#### Kafka ACLs

Kafka ACLs are off by default. Turn them on per virtual cluster with `acls_enabled`, and manage ACLs with any Kafka admin client authenticated as a superuser:

```toml
[[virtual_clusters]]
id = "vci_0f1c2d3e_4a5b_4c6d_8e7f_9a0b1c2d3e4f"
name = "vcn_orders"
target_state_machine_version_max = true
acls_enabled = true

[[virtual_clusters.sasl_credentials]]
username = "admin"
password = "${ADMIN_PASSWORD}"
is_superuser = true

[[virtual_clusters.sasl_credentials]]
username = "orders-app"
password = "${ORDERS_APP_PASSWORD}"
```

- `acls_enabled = true` requires at least one superuser: a SASL credential with `is_superuser = true`, or an [external superuser](#superusers-without-sasl-credentials). Superusers bypass ACLs, so they can create the ACLs everyone else needs.
- `acl_shadowing_enabled = true` logs the requests ACLs would deny, without denying them. Use it to check your ACLs before enforcing them. It can't be combined with `acls_enabled = true`.
- The control plane applies these options when it starts. Removing them leaves the virtual cluster as it is, so set `acls_enabled = false` to turn ACLs off.

##### Superusers Without SASL Credentials

Clients that authenticate without SASL credentials, such as with mTLS or OAuth, can be superusers too. List their principals in `external_superusers`:

```toml
[[virtual_clusters]]
id = "vci_0f1c2d3e_4a5b_4c6d_8e7f_9a0b1c2d3e4f"
name = "vcn_orders"
target_state_machine_version_max = true
acls_enabled = true
external_superusers = ["CN=kafka-admin,O=acme"]
```

- For mTLS, use the client certificate's distinguished name, which `warpstream cli certificate-to-dn -tls-client-cert-file <certificate>` prints. If the agents set `-tlsPrincipalMappingRule`, use the mapped principal instead.
- The same principal can be a superuser in several virtual clusters: list it in each of them.

#### Keeping Secrets Out of the Configuration File

Set `config.expandEnv` to `true` to replace `${VAR}` (or `${VAR:default}`) with environment variables, then inject them from your own Secrets:

```yaml
config:
  expandEnv: true
extraEnv:
  - name: AGENT_KEY
    valueFrom:
      secretKeyRef:
        name: warpstream-agent-key
        key: key
  - name: ORDERS_APP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: orders-app-sasl
        key: password
```

### Connecting Agents

Deploy agents with the [warpstream-agent](../warpstream-agent) chart and point them at the control plane Service:

```yaml
config:
  metadataURL: http://warpstream-control-plane-warpstream-self-hosted-control-plane.<YOUR_NAMESPACE>.svc.cluster.local:8080
  virtualClusterID: <WARPSTREAM_VIRTUAL_CLUSTER_ID>
  agentKeySecretKeyRef:
    name: warpstream-agent-key
    key: key
  bucketURL: <WARPSTREAM_BUCKET_URL>
```

Use the agent version WarpStream recommends with your control plane release. With [TLS](#tls), use `https://` and port `8443` in `metadataURL` instead.

The agent chart's dedicated metrics pod scrapes cluster metrics from the control plane. Agents up to v847 scrape WarpStream Cloud instead by default and fail with `401 invalid username/password`. For those versions, set:

```yaml
dedicatedMetricsPod:
  extraEnv:
    - name: WARPSTREAM_ENABLE_CONTROL_PLANE_PROMETHEUS_ENDPOINT
      value: "true"
```


## Other Deployment Options

### Metrics

The control plane exposes Prometheus metrics on `/metrics` on `ports.http` (`8080` by default), over plain HTTP even with [TLS](#tls). Datadog metrics, profiling and tracing can be enabled with `metrics.datadog`.

#### Prometheus Operator

The helm chart has native support for creating service monitors for the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).

To configure this set the following in your `values.yaml`

```yaml
serviceMonitor:
  enabled: true
```

### Network Policy

Setting `networkPolicy.enabled` to `true` creates a NetworkPolicy that only allows the agent ports (`8080`, and `8443` with [TLS](#tls)) from `networkPolicy.agentIngressFrom` (or from anywhere if it is empty), and the replica-to-replica ports (`8081` and `8082` by default) from other control plane pods.

```yaml
networkPolicy:
  enabled: true
  agentIngressFrom:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: warpstream-agent
```

### TLS

The control plane can encrypt its traffic with agents (`tls`) and between its replicas (`internalTLS`). Both read the certificates from Secrets and reload them when the Secrets change, e.g. when cert-manager renews them.

#### Agent Traffic

With `tls.enabled`, agents connect over HTTPS on `ports.https` (`8443` by default). `ports.http` (`8080`) keeps serving health checks and `/metrics` over plain HTTP, so probes and Prometheus don't need TLS, but no longer serves agents.

`tls.secretName` is a Secret with `tls.crt` and `tls.key`. The certificate must be valid for the hostname in the agents' `metadataURL`, e.g. the Service's DNS name:

```shell
kubectl create secret tls control-plane-tls \
    --namespace $YOUR_NAMESPACE \
    --cert=<PATH_TO_CERT> \
    --key=<PATH_TO_KEY>
```

```yaml
tls:
  enabled: true
  secretName: control-plane-tls
```

Point the agents at `https://` and port `8443`. If the certificate isn't signed by a publicly trusted CA, mount the CA in the agents and pass it with `WARPSTREAM_HTTPS_PROXY_CA_CERT_FILE`, which adds it to the CAs the agents trust:

```yaml
config:
  metadataURL: https://warpstream-control-plane-warpstream-self-hosted-control-plane.<YOUR_NAMESPACE>.svc.cluster.local:8443
extraEnv:
  - name: WARPSTREAM_HTTPS_PROXY_CA_CERT_FILE
    value: /etc/private/ssl/control-plane-ca/ca.crt
volumes:
  - name: control-plane-ca
    secret:
      secretName: control-plane-ca
volumeMounts:
  - name: control-plane-ca
    mountPath: /etc/private/ssl/control-plane-ca
    readOnly: true
dedicatedMetricsPod:
  extraEnv:
    - name: WARPSTREAM_HTTPS_PROXY_CA_CERT_FILE
      value: /etc/private/ssl/control-plane-ca/ca.crt
```

The dedicated metrics pod doesn't inherit `extraEnv`, so it's set again under `dedicatedMetricsPod`. Agents up to v850 don't support `WARPSTREAM_HTTPS_PROXY_CA_CERT_FILE` in the metrics pod; set `SSL_CERT_FILE` to the same path there instead.

#### Traffic Between Replicas

With `internalTLS.enabled`, replicas talk to each other over HTTPS on `ports.clusterRegistry` and `ports.clusterEnvironment` (`8081` and `8082`).

`internalTLS.secretName` is a Secret with `tls.crt`, `tls.key` and `ca.crt`. Replicas verify each other's certificates against `ca.crt` but not their hostnames, so the certificate doesn't need the pods' names or IPs. With `internalTLS.requireMTLS`, each replica also presents `tls.crt` as its client certificate and rejects replicas without one signed by `ca.crt`. `internalTLS.spiffe` additionally requires the client certificate to have the SPIFFE ID `spiffe://<trustDomain>/<workloadID>`:

```yaml
internalTLS:
  enabled: true
  secretName: control-plane-internal-tls
  requireMTLS: true
  spiffe:
    trustDomain: example.com
    workloadID: warpstream-control-plane
```

Replicas with and without `internalTLS` can't talk to each other, so turning it on or off can't be a rolling update. Scale the control plane to 0 first, then upgrade, which sets the replicas back:

```shell
kubectl scale deployment/warpstream-control-plane-warpstream-self-hosted-control-plane \
    --namespace $YOUR_NAMESPACE \
    --replicas=0
kubectl wait pod \
    --namespace $YOUR_NAMESPACE \
    --selector app.kubernetes.io/instance=warpstream-control-plane \
    --for=delete \
    --timeout=15m
helm upgrade warpstream-control-plane warpstream/warpstream-self-hosted-control-plane \
    --namespace $YOUR_NAMESPACE \
    --values warpstream-values.yaml
```

Agents keep running, but can't reach the control plane until the replicas are back. Changing the certificates themselves doesn't need a restart.

### Application Load Balancer

To reach the control plane from agents outside the cluster, for example in another cluster or VPC, set `ingress.enabled` to put an internal Application Load Balancer in front of it with the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) or EKS Auto Mode:

```yaml
ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /v1/readiness
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "10"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
    alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds=30
```

Set `ingress.className` to the name of the ALB IngressClass in your cluster.

With [TLS](#tls), the Ingress routes to port `8443`. Add `alb.ingress.kubernetes.io/backend-protocol: HTTPS` so the load balancer connects to the control plane over HTTPS.

Use the load balancer's DNS name as the agents' `metadataURL`:

```yaml
config:
  metadataURL: http://<LOAD_BALANCER_DNS_NAME>
```

### Availability Zone Management

Replicas are spread across availability zones by default (`zoneSpread.enabled`). The spread is strict (`zoneSpread.whenUnsatisfiable: DoNotSchedule`), so a replica stays `Pending` rather than landing in a zone that already has more than its share. Set `zoneSpread.whenUnsatisfiable` to `ScheduleAnyway` to relax it, or set `zoneSpread.enabled` to `false` and use `topologySpreadConstraints` for a custom spread.

The control plane determines its availability zone by reading its pod and node from the Kubernetes API, which the chart's RBAC (`rbac.create`) allows.


## Troubleshooting

- **`invalid enterprise license key`**: check the license Secret and key name.
- **`this enterprise license is restricted to regions ...`**: the control plane is running in a region your license doesn't cover, or it couldn't determine its availability zone. Check that `rbac.create` is `true` and that your nodes have the `topology.kubernetes.io/zone` label.
- **`error verifying access to object storage`**: the role can't read or write `config.snapshotBucketURL`.
- **DynamoDB `AccessDeniedException`**: the table names in the IAM policy don't match `warpstream_cluster_name`.
- **Pods stuck not ready**: check the logs of all replicas. They need to reach each other on ports `8081` and `8082`.
- **Agent metrics pod logs `401 invalid username/password`**: the agent version predates scraping the control plane by default. See [Connecting Agents](#connecting-agents).
- **`acls_enabled requires an external superuser or a SASL credential with is_superuser = true`**: add a superuser to that virtual cluster. See [Kafka ACLs](#kafka-acls).
- **An mTLS client listed in `external_superusers` isn't treated as a superuser**: check that the entry matches the output of `warpstream cli certificate-to-dn` for its certificate exactly, or the mapped principal if the agents set `-tlsPrincipalMappingRule`.
- **`SASL usernames must be unique`**: a username is used by more than one SASL credential, possibly in different virtual clusters.
- **Agents or the agent metrics pod log `x509: certificate signed by unknown authority`**: they don't trust the CA of the `tls` certificate. See [Agent Traffic](#agent-traffic).
- **`client sent an HTTP request to an HTTPS server`**: with `tls`, agents use `http://` in `metadataURL`. With `internalTLS`, replicas with and without it are running at the same time; see [Traffic Between Replicas](#traffic-between-replicas).
- **`tls: client didn't provide a certificate`** or **`invalid spiffe uri`**: with `internalTLS.requireMTLS`, a replica's certificate isn't signed by `ca.crt` or doesn't have the SPIFFE ID in `internalTLS.spiffe`.

Contact WarpStream support with the control plane logs and your release version for anything else.


## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.repository | string | ` ` | Required. The control plane image repository provided by WarpStream, or your mirror of it |
| image.tag | string | ` ` | Required. The control plane release, e.g. `2026-w41` |
| image.pullPolicy | string | `IfNotPresent` | The image pull policy |
| imagePullSecrets | list | `[]` | Optional array of imagePullSecrets containing private registry credentials # Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| nameOverride | string | ` ` | |
| fullnameOverride | string | ` ` | |
| replicas | number | `3` | The number of control plane replicas. Must be at least 3 |
| config.clusterConf | string | ` ` | The contents of the [configuration file](#configuration-file) |
| config.existingSecret | string | ` ` | The name of an existing secret holding the configuration file, instead of `config.clusterConf` |
| config.existingSecretKey | string | `config.toml` | The key of the configuration file in `config.existingSecret` |
| config.expandEnv | bool | `false` | Replace `${VAR}` references in the configuration file with environment variables |
| config.snapshotBucketURL | string | ` ` | Required. The object storage URL for metadata snapshots |
| config.clusterMode | string | `dynamodb-production` | The metadata store backend |
| license.key | string | ` ` | The enterprise license key |
| license.existingSecret | string | ` ` | The name of an existing secret holding the license key, instead of `license.key` |
| license.existingSecretKey | string | `license-key` | The key of the license key in `license.existingSecret` |
| ports.http | number | `8080` | The agent, health check and metrics port. Only health checks and metrics with `tls.enabled` |
| ports.https | number | `8443` | The agent port with `tls.enabled` |
| ports.clusterRegistry | number | `8081` | Replica-to-replica port |
| ports.clusterEnvironment | number | `8082` | Replica-to-replica port |
| tls.enabled | bool | `false` | Serve the agent API over HTTPS on `ports.https` |
| tls.secretName | string | ` ` | Required with `tls.enabled`. The name of a secret with `tls.crt` and `tls.key` |
| internalTLS.enabled | bool | `false` | Encrypt the traffic between replicas. Can't be turned on or off with a rolling update |
| internalTLS.secretName | string | ` ` | Required with `internalTLS.enabled`. The name of a secret with `tls.crt`, `tls.key` and `ca.crt` |
| internalTLS.requireMTLS | bool | `false` | Require replicas to present a client certificate signed by `ca.crt` |
| internalTLS.spiffe.trustDomain | string | ` ` | Require the SPIFFE ID `spiffe://<trustDomain>/<workloadID>` on client certificates. Requires `internalTLS.requireMTLS` |
| internalTLS.spiffe.workloadID | string | ` ` | |
| metrics.prometheus | bool | `true` | Enable/disable Prometheus metrics |
| metrics.datadog.metrics | bool | `false` | Enable/disable Datadog metrics |
| metrics.datadog.profiling | bool | `false` | Enable/disable Datadog profiling |
| metrics.datadog.tracing | bool | `false` | Enable/disable Datadog tracing |
| service.type | string | `ClusterIP` | The service type |
| service.annotations | object | `{}` | Additional annotations to add to the service |
| ingress.enabled | bool | `false` | Create an Ingress for the agent port (`ports.https` with `tls.enabled`) |
| ingress.className | string | ` ` | The IngressClass to use, e.g. `alb` |
| ingress.annotations | object | `{}` | Additional annotations to add to the Ingress |
| ingress.host | string | ` ` | Only route requests for this host. Routes all requests when empty |
| serviceMonitor.enabled | bool | `false` | Create a Prometheus Operator ServiceMonitor |
| serviceMonitor.interval | string | `30s` | |
| serviceMonitor.scrapeTimeout | string | `10s` | |
| serviceMonitor.labels | object | `{}` | Additional labels to add to the ServiceMonitor |
| serviceAccount.create | bool | `true` | Create a service account |
| serviceAccount.name | string | ` ` | The name of the service account. Generated from the fullname when empty |
| serviceAccount.annotations | object | `{}` | Additional annotations to add to the service account, e.g. the IRSA role ARN |
| serviceAccount.automountServiceAccountToken | bool | `true` | Required for availability zone detection |
| rbac.create | bool | `true` | Allow the control plane to read its pod and node to determine its availability zone |
| annotations | object | `{}` | Additional annotations to add to all created resources |
| podAnnotations | object | `{}` | Additional annotations to add to control plane pods |
| podLabels | object | `{}` | Additional labels to add to control plane pods |
| resources | object | `{"requests":{"cpu":2,"memory":"16Gi"},"limits":{"memory":"16Gi"}}` | |
| podSecurityContext | object | `{}` | |
| securityContext | object | `{}` | |
| terminationGracePeriodSeconds | number | `720` | The amount of seconds Kubernetes will wait to force kill the pod after initially terminating. Replicas shut down one at a time, which can take several minutes |
| minReadySeconds | number | `120` | |
| strategy | object | `{"type":"RollingUpdate","rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}` | |
| startupProbe | object | `/v1/status` | |
| livenessProbe | object | `/v1/status` | |
| readinessProbe | object | `/v1/readiness` | |
| pdb.create | bool | `true` | Create a PodDisruptionBudget |
| pdb.maxUnavailable | number | `1` | |
| zoneSpread.enabled | bool | `true` | Spread replicas across availability zones |
| zoneSpread.maxSkew | number | `1` | |
| zoneSpread.whenUnsatisfiable | string | `DoNotSchedule` | |
| topologySpreadConstraints | list | `[]` | Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/ |
| nodeSelector | object | `{}` | |
| tolerations | list | `[]` | |
| affinity | object | `{}` | |
| priorityClassName | string | ` ` | |
| networkPolicy.enabled | bool | `false` | Create a NetworkPolicy |
| networkPolicy.agentIngressFrom | list | `[]` | Sources allowed to reach the agent port. Allows all sources when empty |
| extraEnv | list | `[]` | Extra environment variables to add to the control plane |
| extraEnvFrom | list | `[]` | Extra environment variables to add to the control plane |
| extraArgs | list | `[]` | Extra arguments to add to the control plane |
| extraVolumes | list | `[]` | Extra volumes to add to the control plane |
| extraVolumeMounts | list | `[]` | Extra volume mounts to add to the control plane |

## Development

### Publishing a New Release

1. When changing any Helm chart resources: Update `version` in [`Chart.yaml`](./Chart.yaml) and add an entry to [`CHANGELOG.md`](./CHANGELOG.md).
