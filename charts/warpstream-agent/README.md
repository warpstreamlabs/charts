# WarpStream

[WarpStream](https://www.warpstream.com/) is an Apache Kafka® compatible data streaming platform built directly on top of object storage. This Helm chart simplifies the deployment of WarpStream agents into your Kubernetes cluster using the "Bring Your Own Cloud" (BYOC) model.


## Using the WarpStream Helm repository

Start by adding this repository to your Helm repositories:

```
helm repo add warpstream https://warpstreamlabs.github.io/charts
helm repo update
```


## Prerequisites

Helm v3.6 or later.


## Quickstart

By default, the WarpStream deployment runs as a ClusterIP Service with auto-scaling and authentication disabled and requires additional steps to grant the pods permission to access object storage.

### Installing the WarpStream Chart

Before installing the WarpStream Chart, create a new BYOC cluster in your [WarpStream Console](https://console.warpstream.com/) to obtain the values needed below. See [Required Arguments](https://docs.warpstream.com/warpstream/byoc/deploy#required-arguments) for more details.

```shell
helm repo add warpstream https://warpstreamlabs.github.io/charts
helm repo update
helm upgrade --install warpstream-agent warpstream/warpstream-agent \
    --namespace $YOUR_NAMESPACE \
    --set config.bucketURL="$YOUR_OBJECT_STORE" \
    --set config.agentKey="$YOUR_API_KEY" \
    --set config.region="$YOUR_CONTROL_PLANE_REGION" \
    --set config.virtualClusterID="$YOUR_VIRTUAL_CLUSTER_ID"
```

The chart creates a Kubernetes Secret for the Agent key. You can also create a secret manually and set 
`config.agentKeySecretKeyRef.name` and `config.agentKeySecretKeyRef.key` to the name of your Kubernetes secret and 
the data key name within that secret.

As an alternative to supplying the configuration parameters as arguments, you can create a supplemental YAML file containing your specific config parameters. Any parameters not specified in this file will default to those set in [values.yaml](values.yaml).

1. Create an empty `warpstream-values.yaml` file
2. Edit the file with your specific parameters:

```yaml
config:
  bucketURL: <WARPSTREAM_BUCKET_URL>
  agentKey: <WARPSTREAM_AGENT_KEY>
  virtualClusterID: <WARPSTREAM_VIRTUAL_CLUSTER_ID>
  region: <WARPSTREAM_CLUSTER_REGION>
```

3. Install or upgrade the WarpStream Helm chart using your custom yaml file:

```shell
helm upgrade --install warpstream-agent warpstream/warpstream-agent --namespace $YOUR_NAMESPACE -f warpstream-values.yaml
```

### Upgrading

To upgrade the deployment:

```shell
helm repo update
helm upgrade warpstream-agent warpstream/warpstream-agent --namespace $YOUR_NAMESPACE --reuse-values
```

### Uninstalling the Chart

To uninstall/delete the deployment:

```shell
helm uninstall warpstream-agent
```

This command removes all the Kubernetes components associated with the chart and deletes the release.


## Deployment Considerations

Before installing, consider:
- **Networking**: How will your clients communicate with your WarpStream cluster?
- **Scaling**: How will your cluster adapt to changes in load?
- **Object Storage Access**: How will your pods authenticate requests to your object storage?
- **Authentication**: How will your clients securely connect with your WarpStream cluster?

### Networking
As with any Kubernetes deployment, there are a variety of network topologies available, but two will be highlighted here.
1. **Direct Route** (recommended) - a network route exists for clients to connect directly with each pod

In this scenario, the deployment utilizes the built-in load-balancing provided by the WarpStream Service Discovery to round-robin client connections to the available pods. Learn more about WarpStream's custom service discovery in the [Service Discovery](https://docs.warpstream.com/warpstream/overview/architecture/service-discovery#kafka-service-discovery) documentation. In this configuration, each pod will need to be reachable from the clients via the internal IP which it advertises as part of the Service Discovery process.

2. **Load Balancer/Proxy** - clients connect to the agents via a traditional network load balancer or proxy

In this scenario, because the WarpStream agents are entirely stateless, they can be deployed behind a network load balancer. This means clients only need to be able to reach the load balancer. The key to this configuration is that all agents need to advertise the hostname or IP of the load balancer instead of their local IP. Read more about this option [here](https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/configure-warpstream-agent-within-a-container-or-behind-a-proxy).


### Scaling
WarpStream clusters can auto-scale easily due to the stateless nature of agents. The recommendation is to auto-scale based on CPU usage with a 50% average usage target. Auto-scaling is disabled by default in the Helm chart (3 replicas are used instead). See `autoscaling` in [values.yaml](values.yaml) for the available options.

### Object Storage Access
WarpStream agents rely on object storage as opposed to local disks. This means each pod needs permissions to access your object storage bucket. Configuration varies depending on your cloud provider. See [Object Storage Configuration](https://docs.warpstream.com/warpstream/byoc/deploy/different-object-stores) for more details.

Other useful references:
- https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html
- https://azure.github.io/azure-workload-identity/docs/introduction.html
- https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

### Authentication
WarpStream supports secure authentication and encryption via SASL and TLS, although neither is enabled by default. 

If you plan to expose the WarpStream Agents outside your VPC (I.E to the public internet), enabling both is highly recommended. See the [Authentication](https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/enable-agent-auth) documentation for more details.

### Kubernetes Equal Spread

Idealy when deploying WarpStream Kubernetes will equally distribute pods across all nodes and zones. However in some
cases Kubernetes may not equally spread the pods across zones which will limit high availability of the WarpStream
cluster. 

[This document](https://docs.warpstream.com/warpstream/byoc/deploy/kubernetes-known-issues#when-running-in-kubernetes-warpstream-pods-end-up-in-the-same-zone-or-node) contains details
and a solution to force Kubernetes to equally spread the pods across nodes and zones.

## Other Deployment Options

### LoadBalancer Service
The stateless nature of the WarpStream agents allows them to be deployed behind a network load balancer using `type: LoadBalancer` in your Service configuration. See the [Kubernetes Service documentation](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) for details.

Update your Helm chart configuration with these parameters:

```yaml
kafkaService:
  enabled: true
  type: LoadBalancer

extraEnv: 
  - name: WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE
    value: <LOAD_BALANCER_DNS HOSTNAME>
```

Follow your cloud provider's load balancer documentation to complete the configuration.

**Note**
If your load balancer is exposed to the internet, enabling authentication on the WarpStream agents is highly recommended. See [Authentication](https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/enable-agent-auth) for more details, including how to create the client credentials in the WarpStream console.

Enable authentication by setting the `WARPSTREAM_REQUIRE_AUTHENTICATION` variable:

```yaml
kafkaService:
  enabled: true
  type: LoadBalancer

extraEnv: 
  - name: WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE
    value: <LOAD_BALANCER_DNS HOSTNAME>
  - name: WARPSTREAM_REQUIRE_AUTHENTICATION
    value: "true"
```

### Playground Mode
Use playground mode to easily test WarpStream without needing to first create a WarpStream account. See WarpStream's ["Hello World"](https://docs.warpstream.com/warpstream/getting-started/hello-world-using-kafka) to learn more.

Playground mode can also be used for testing the WarpStream Kubernetes deployment in local environments such as [kind][], [minikube][], or [Rancher Desktop][].

[kind]: https://kind.sigs.k8s.io/
[minikube]: https://minikube.sigs.k8s.io/docs/
[Rancher Desktop]: https://rancherdesktop.io/

**Warning**
In playground mode the agent is configured to store all data in memory. This means, if the pod is restarted for any reason, the data will be lost.

Run in playground mode:
```shell
helm upgrade --install warpstream-agent warpstream/warpstream-agent --set config.playground=true
```

Verify the temporary deployment:
```shell
helm test warpstream-agent
kubectl logs warpstream-agent-diagnose-connection
```

Obtain the temporary WarpStream console URL:
```shell
kubectl logs deployment/warpstream-agent
```


## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| podLabels | object | `{}` | Additional labels to add to WarpStream Agent pods |
| annotations | object | `{}` | Additional annotations to add to all created resources |
| image.repository | string | `public.ecr.aws/warpstream-labs/warpstream_agent` | The container image to use |
| image.pullPolicy | string | `IfNotPresent` | The image pull policy |
| image.tag | string | ` ` | The image tag |
| imagePullSecrets | list | `[]` | Optional array of imagePullSecrets containing private registry credentials # Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/ |
| nameOverride | string | ` ` | |
| fullnameOverride | string | ` ` | |
| replicas | number | `3` | The number of agent replicas to deploy when autoscaling is disabled |
| deploymentKind | string | `Deployment` | Deploy the agents using a `Deployment` or `StatefulSet`. |
| revisionHistoryLimit | number | `10` | The number of deployment revision replicasets to keep in Kubernetes |
| terminationGracePeriodSeconds | number | `600` | The amount of seconds Kubernetes will wait to force kill the pod after initially terminating |
| securityContext | object | `{}` | |
| goMaxProcs | number | ` ` | Override the calculated GOMAXPROCS from `resources.requests.cpu` |
| extraEnv | list | `[]` | Extra environment variables to add to the WarpStream Agent |
| extraEnvFrom | list | `[]` | Extra environment variables to add to the WarpStream Agent |
| volumeMounts | list | `[]` | Extra volume mounts to add to the WarpStream Agent |
| volumes | list | `[]` | Extra volumes to add to the WarpStream Agent |
| extraArgs | list | `[]` | Extra arguments to add to the WarpStream Agent |
| nodeSelector | object | `{}` | |
| tolerations | list | `[]` | |
| affinity | object | `{}` | |
| topologySpreadConstraints | list | `[]` | Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
| priorityClassName | string | ` ` | |
| hostAliases | list | `[]` | |
| initContainers | list | `[]` | |
| dnsConfig | object | `{}` | |
| deploymentStrategy.type | string | `RollingUpdate` | |
| deploymentStrategy.rollingUpdate.maxSurge | number | `1` | |
| deploymentStrategy.rollingUpdate.maxUnavailable | number | `1` | |
| statefulSetConfig.clusterDomain | string | `cluster.local` | The domain to use when configuring the statefulset |
| statefulSetConfig.podManagementPolicy | string | `Parallel` | Ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#pod-management-policies |
| statefulSetConfig.updateStrategy.type | string | `RollingUpdate` | Ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies |
| statefulSetConfig.disableAutomaticHostnameOverride | bool | `false` | Disables setting WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE automatically to the pod hostname |
| certificate.enableTLS | bool | `false` | Enable TLS termination on the WarpStream Agents |
| certificate.certManager.create | bool | `false` | Enable cert-manager to manage the certificates |
| certificate.certManager.subject | object | `{}` | X509 Certificate Subject Ref: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.X509Subject | 
| certificate.certManager.issuer.ref | object | `{}` | |
| certificate.certManager.dnsNames | list | `[]` | Override the default DNS names used to create the certificate |
| certificate.secretName | string | ` ` | The TLS Kubernetes secret name containing the certificate. Only used when not using cert-manager Ref: https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets |
| certificate.mtls.enabled | bool | `false` | Enable MTLS Ref: https://docs.warpstream.com/warpstream/byoc/authentication/mutual-tls-mtls |
| certificate.mtls.certificateAuthoritySecretKeyRef.name | string | ` ` | The secret name for the certificate authority public key |
| certificate.mtls.certificateAuthoritySecretKeyRef.key | string | ` ` | The secret key for the certificate authority public key |
| serviceAccount.create | bool | `true` | |
| serviceAccount.automountServiceAccountToken | bool | `true` | |
| serviceAccount.annotations | object | `{}` | Additional annotations to add to the created service account |
| serviceAccount.name | string | `null` | Override the name of the created service account |
| rbac.create | bool | `true` | |
| service.type | string | `ClusterIP` | |
| service.port | number | `9092` | |
| service.httpPort | number | `8080` | |
| service.schemaRegistryPort | number | `9094` | |
| service.labels | object | `{}` | Additional labels to add to the service |
| service.loadBalancerSourceRanges | list | `[]` | |
| service.perPod | bool | `false` | Create a unique service for each Kubernetes pod, typically only used when using Kong or Isto ingresses |
| headlessService.enabled | bool | `false` | Enable the headless service |
| kafkaService.enabled | bool | `false` | Enable the additional kafka service |
| kafkaService.type | string | `ClusterIP` | |
| kafkaService.port | number | `9092` | |
| kafkaService.loadBalancerSourceRanges | list | `[]` | |
| bentoService.enabled | bool | `false` | Enable the additional bento service |
| bentoService.type | string | `ClusterIP` | |
| bentoService.port | number | `4195` | |
| bentoService.extraPorts | list | `[]` | Additional ports to add to the bento service |
| config.configMapEnabled | bool | `true` | Enable create the configmap to configure the WarpStream Agents, only set to `false` if you are configuring the agent via `extraEnv` or `extraEnvFrom` |
| config.playground | bool | `false` | Enable playground mode Ref: https://docs.warpstream.com/warpstream/reference/cli-reference/warpstream-playground |
| config.bucketURL | string | ` ` | The bucket URL to use for storage |
| config.virtualClusterID | string | ` ` | The WarpStream virtual cluster ID |
| config.region | string | ` ` | The control plane region for the WarpStream cluster |
| config.metadataURL | string | ` ` | The metadata URL of the WarpStream control plane, only used for private link or dedicated control planes |
| config.agentKey | string | ` ` | The agent key, the helm chart will manage the Kubernetes secret that the key is stored in | 
| config.agentKeySecretKeyRef.name | string | ` ` | The Kubernetes secret name that contains the agent key |
| config.agentKeySecretKeyRef.key | string | ` ` | The Kubernetes secret key that contains the agent key |
| config.agentGroup | string | ` ` | The optional agent group to use Ref: https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/agent-groups |
| config.ingestionBucketURL | string | ` ` | The optional ingestion bucket URL, usually used for low latency clusters https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/low-latency-clusters |
| config.compactionBucketURL | string | ` ` | The optional compaction bucket URL, usually used for low latency clusters https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/low-latency-clusters |
| enforceProductionResourceRequirements | bool | `true` | Enforce production resource requirements, 1:4 CPU to memory ratios |
| resources.requests.cpu | string | `4` | |
| resources.requests.memory | string | `16Gi` | |
| resources.requests.ephemeral-storage | string | `100Mi` | Ephemeral Storage requests, used to inform Kubelet about the agent potentially generating lots of logs |
| resources.limits.memory | string | `16Gi` | Should be set to the same as `resources.requests.memory` |
| availabilityZoneSelector.enabled | bool | `false` | Enable deploying into a single availability zone |
| availabilityZoneSelector.zone | string | `us-east-1a` | The single availability zone to deploy into |
| availabilityZoneSelector.nodeZoneLabel | string | `topology.kubernetes.io/zone` | The node label to select the availability zone from |
| autoscaling.enabled | bool | `true` | Enable autoscaling the WarpStream Agents |
| autoscaling.minReplicas | number | `3` | The minimum number of autoscaling WarpStream Agents |
| autoscaling.maxReplicas | number | `30` | The maximum number of autoscaling WarpStream Agents |
| autoscaling.targetCPU | string | `60` | The target CPU percentage to keep the pods scaled at |
| autoscaling.targetMemory | string | ` ` | The target memory percentage to keep the pods scaled at |
| autoscaling.behavior | object | ` ` | The scale up and down behavior, see `values.yaml` for defaults |
| pdb.create | bool | `true` | Create a pod distruption budget |
| pdb.maxUnavailable | number | `1` | |
| serviceMonitor.enabled | bool | `false` | Enable creating a prometheus operator service monitor |
| prometheusRule.enabled | bool | `false` | Enable creating a prometheus operator prometheus rule |
| scrapeConfig.enabled | bool | `false` | Enable creating a prometheus operator scrape config |
| networkPolicy.enabled | bool | `false` | Create a network policy |
| networkPolicy.ingressRules | object | `{}` | The network policy ingress rules |
| networkPolicy.egressRules | object | `{}` | The network policy egress rules |

## Development

### Publishing a new release

1. When applicable: Update `appVersion` in [`Chart.yaml`](./Chart.yaml) with the latest [release][].
1. When changing any Helm chart resources: Update `version` in [`Chart.yaml`](./Chart.yaml).

[release]: https://docs.warpstream.com/warpstream/reference/install-the-warpstream-agent
