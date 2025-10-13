# WarpStream

[WarpStream](https://www.warpstream.com/) is an Apache Kafka® compatible data streaming platform built directly on top of object storage. This Helm chart simplifies the deployment of WarpStream agents into your Kubernetes cluster using the "Bring Your Own Cloud" (BYOC) model.

## Using the WarpStream Helm Repository

Start by adding this repository to your Helm repositories:

```shell
helm repo add warpstream https://warpstreamlabs.github.io/charts
helm repo update
```


## Prerequisites

Helm v3.6 or later.


## Quickstart

By default, the WarpStream deployment runs as a ClusterIP Service with auto-scaling and authentication disabled. Additional steps are required to grant the pods permission to access object storage.

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

The chart creates a Kubernees Secret for the Agent key. You can also create a secret manually and set  `config.agentKeySecretKeyRef.name` and `config.agentKeySecretKeyRef.key` to the name of your Kubernetes secret and  the data key name within that secret.

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

3. Install or upgrade the WarpStream Helm chart using your custom YAML file:

```shell
helm upgrade --install warpstream-agent warpstream/warpstream-agent \
    --namespace $YOUR_NAMESPACE \
    -f warpstream-values.yaml
```

### Upgrading

To upgrade the deployment:

```shell
helm repo update
helm upgrade warpstream-agent warpstream/warpstream-agent \
    --namespace $YOUR_NAMESPACE \
    --reuse-values
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

As with any Kubernetes deployment, there are a variety of network topologies available, but two will be highlighted here:

1. **Direct Route** (recommended) - A network route exists for clients to connect directly with each pod

   In this scenario, the deployment utilizes the built-in load-balancing provided by the WarpStream Service Discovery to round-robin client connections to the available pods. Learn more about WarpStream's custom service discovery in the [Service Discovery](https://docs.warpstream.com/warpstream/overview/architecture/service-discovery#kafka-service-discovery) documentation. In this configuration, each pod will need to be reachable from the clients via the internal IP which it advertises as part of the Service Discovery process.

2. **Load Balancer/Proxy** - Clients connect to the agents via a traditional network load balancer or proxy

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

If you plan to expose the WarpStream Agents outside your VPC (i.e., to the public internet), enabling both is highly recommended. See the [Authentication](https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/enable-agent-auth) documentation for more details.

### Kubernetes Equal Spread

Ideally, when deploying WarpStream, Kubernetes will equally distribute pods across all nodes and zones. However, in some
cases, Kubernetes may not equally spread the pods across zones, which will limit the high availability of the WarpStream
cluster. 

[This document](https://docs.warpstream.com/warpstream/byoc/deploy/kubernetes-known-issues#when-running-in-kubernetes-warpstream-pods-end-up-in-the-same-zone-or-node) contains details
and a solution to force Kubernetes to equally spread the pods across nodes and zones.

## Other Deployment Options

### Managed Data Pipelines

Managed Data Pipelines is a feature that enables WarpStream to connect to external systems using simple, declarative configuration, with the configuration managed by WarpStream. Managed Data Pipelines can also do lightweight, stateless stream processing. Managed Data Pipelines is powered by [Bento](https://warpstreamlabs.github.io/bento/). 

Managed Data Pipelines is off by default. Enable Managed Data Pipelines by setting the `WARPSTREAM_ENABLE_MANAGED_PIPELINES` variable:

```yaml
extraEnv:
  - name: WARPSTREAM_ENABLE_MANAGED_PIPELINES
    value: "true"
```

### Kafka LoadBalancer Service

The stateless nature of the WarpStream agents allows them to be deployed behind a network load balancer using `type: LoadBalancer` in your Service configuration. See the [Kubernetes Service documentation](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) for details.

Update your Helm chart configuration with these parameters:

```yaml
kafkaService:
  enabled: true
  type: LoadBalancer

extraEnv: 
  - name: WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE
    value: <LOAD_BALANCER_DNS_HOSTNAME>
```

Follow your cloud provider's load balancer documentation to complete the configuration.

**Note**: If your load balancer is exposed to the internet, enabling authentication on the WarpStream agents is highly recommended. See [Manage Security](https://docs.warpstream.com/warpstream/kafka/manage-security) for more details, including how to create the client credentials in the WarpStream console.

Enable authentication by setting the `WARPSTREAM_REQUIRE_AUTHENTICATION` variable:

```yaml
kafkaService:
  enabled: true
  type: LoadBalancer

extraEnv: 
  - name: WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE
    value: <LOAD_BALANCER_DNS_HOSTNAME>
  # Optionally require SASL authentication (or WARPSTREAM_REQUIRE_MTLS_AUTHENTICATION for mTLS authentication)
  - name: WARPSTREAM_REQUIRE_SASL_AUTHENTICATION
    value: "true"
```

**Note:** This helm chart has multiple services it is recommended to only set the required services to `LoadBalancer` and leave the other services as `ClusterIP`. Setting the other services in this helm chart to 
`LoadBalancer` could expose internal WarpStream Agent functionality like the agent-to-agent communication endpoints 
or the Bento Managed pipeline endpoints.

### Schema Registry LoadBalancer Service

If may be desirable to deploy a load balancer infront of WarpStream Schema Registry. This can be done byusing `type: 
LoadBalancer` in your Service configuration. See the [Kubernetes Service documentation](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) for details.

**Note**: If your load balancer is exposed to the internet, enabling authentication on the WarpStream agents is highly recommended. See [Manage Security](https://docs.warpstream.com/warpstream/schema-registry/manage-security) for more details, including how to create the client credentials in the WarpStream console.

```yaml
schemaRegistryService:
  enabled: true
  type: LoadBalancer

extraEnv: 
  # Optionally require basic auth authentication
  - name: WARPSTREAM_SCHEMA_REGISTRY_BASIC_AUTH_ENABLED
    value: "true"
```

**Note:** This helm chart has multiple services it is recommended to only set the required services to `LoadBalancer` and leave the other services as `ClusterIP`. Setting the other services in this helm chart to 
`LoadBalancer` could expose internal WarpStream Agent functionality like the agent-to-agent communication endpoints 
or the Bento Managed pipeline endpoints.

### Metrics

WarpStream supports exposing metrics with Prometheus and Datadog. For more information see [Monitoring](https://docs.warpstream.com/warpstream/byoc/monitor-the-warpstream-agents) and [Important Metrics and Logs](https://docs.warpstream.com/warpstream/byoc/monitor-the-warpstream-agents/important-metrics-and-logs).

#### Prometheus Operator

The helm chart has native support for creating service monitors and scrape configurations for the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).

To configure this set the following in your `values.yaml`

```yaml
# To scrape metrics from the WarpStream Agents
serviceMonitor:
  enabled: true

# To scrape metrics from our hosted prometheus endpoint
# Ref: https://docs.warpstream.com/warpstream/byoc/monitor-the-warpstream-agents/hosted-prometheus-endpoint
scrapeConfig:
  enabled: true
```

#### Datadog Agent

To configure the WarpStream agent to push metrics to datadog configure the following in your `values.yaml`.

This example assumes you are running a datadog agent as a daemonset on every Kubernetes node.
If this is not the case in your setup, then the environment variable `DD_AGENT_HOST` will
need to be set to the correct host for your environment.

```yaml
extraEnv:
  - name: DD_AGENT_HOST
    valueFrom:
      fieldRef:
        fieldPath: status.hostIP
  - name: WARPSTREAM_ENABLE_DATADOG_METRICS
    value: "true"
```

**Note:** Datadog Agents can also be configured to pull metrics from the WarpStream Agents, however we recommend
using the above push setup for most installtions.

### Deployment vs Statefulset

Use StatefulSet when TLS is needed for an easier time managing certificates due to stable hostnames.

Or when more control is desired over rolling restarts. With Deployments Kubernetes does not wait for
terminating pods to disappear before moving on, usually this is not a problem, however if you experience
unexpected application behavior during upgrades using StatefulSets may be desired.
This deployment behavior is expected to be configurable in Kubernetes 1.34 https://github.com/kubernetes/enhancements/issues/3973

**Note:** If you switch to using StatefulSet you should stop using WarpStream's convenience bootstrap
URL in your Kafka clients, and switch to the Kubernetes service name instead. The reason for this is that
when you switch to StatefulSet, the Agents will begin advertising their stable pod names in the Kafka
protocol as their hostname, instead of their internal IP addresses. When this happens, WarpStream's DNS
server will start returning CNAME's for the convenience bootstrap URL for each Agent. Since these CNAME's
are private to the Kubernetes cluster WarpStream's DNS server cannot resolve them causing applications
to fail to connect.

For example the WarpStream agents will change from advertising their IP, i.e `10.1.2.3` to advertising their 
hostname, i.e `warpstream-agent-0.warpstream-agent.default.svc.cluster.local`. Your applications should then use 
the following as their bootstrap URL: `warpstream-agent-kafka.default.svc.cluster.local:9092`.

In general, we always recommend using the Kubernetes service name as the bootstrap URL for your clients
when the Agents are deployed in Kubernetes to avoid issues like this.

**Note:** The above documentation about bootstrap URLs and advertise hostname will only work if the client 
applications are in the same Kubernetes cluster as the WarpStream agents. It is possible to make this work for 
external applications by tweaking `statefulSetConfig.clusterDomain` but this is a more advanced topic and requires 
external DNS management that is out of scope for this section.

To use Statefulsets set the following

```yaml
deploymentKind: StatefulSet
```

The statefulset configuration can also be changed. Most of the time these settings don't need to be changed and can 
be left at the defaults bellow.

```yaml
statefulSetConfig:
  clusterDomain: cluster.local
  podManagementPolicy: Parallel  # or OrderedReady, see https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#pod-management-policies
  updateStrategy:
    # see https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#update-strategies
    type: RollingUpdate

  # Disables setting WARPSTREAM_DISCOVERY_KAFKA_HOSTNAME_OVERRIDE automatically to the pod hostname
  # i.e warpstream-agent-0.warpstream-agent-headless.warpstream.svc.cluster.local
  # Disabling this automatic hostname may be desired if using statefulsets for better control over
  # rolling updates.
  # If using TLS disabling the automatic hostname is not recommended as the pods will not longer advertise
  # a stable hostname and revert to advertising their IP address.
  disableAutomaticHostnameOverride: false
```

### Control Plane Private Link

If you have required a private link to the WarpStream control plane you can configure the helm chart to use that
private link by setting `metadataURL`, an example is bellow.

```yaml
metadataURL: "https://private.example.com"
```

**Note:** The URL for the private link will be shared with you by the WarpStream Support team. Do not set this URL
unless told to do so by WarpStream Support as setting it without communication will make the WarpStream Agents fail
to run.

### Availability Zone Management

#### Even Distribution across Zones

By default the helm chart will use Kubernetes' default pod scheduling techniques. This is not always ideal as you
could end up with pods not evenly balances across all zones.

Set the following in your `values.yaml` to require pods to be eenly distributed across all zones in your Kubernetes 
cluster.

```yaml
topologySpreadConstraints:
  # Try to spread pods across multiple zones
  - maxSkew: 1 # +/- one pod per zone
    # Depending on your Kubernetes deployment this label may be different
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    # minDomains is only available in Kubernetes 1.30+
    # Remove this field if you are on an older Kubernetes
    # version.
    # When possible set to the number of available 
    # availability zones in your cluster.
    minDomains: 3
    # Label Selector to select the warpstream deployment
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: warpstream-agent
        app.kubernetes.io/instance: warpstream-agent # Set to your helm release name

affinity:
  # Make sure pods are not scheduled on the same node to prevent bin packing
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    # Label Selector to select the warpstream deployment
    - labelSelector:
        matchLabels:
          app.kubernetes.io/name: warpstream-agent
          app.kubernetes.io/instance: warpstream-agent # Set to your helm release name
      topologyKey: kubernetes.io/hostname
```

#### Autoscaling Per Zone

By default the helm chart will autoscale all zones at the same time, meaning all WarpStream Agents in all zones
must trigger the autoscaling thresholds for pods to be scaled up and down.

This isn't always ideal, especially in situations when there are more clients in one availability zone. In that
case only a single zone should be autoscaled while the rest shouldn't.

To acheive this it is recommended to install the warpstream helm chart 3 different times into the same Kubernetes
cluster each with a unique helm release name but all pointing to the same object storage and all using the same
virtual cluster ID and agent keys.

Then in each chart's `values.yaml` the following should be set

```yaml
# Deployment 1
...
availabilityZoneSelector:
  enabled: true
  zone: "us-east-1a"

  # The node label to select on
  nodeZoneLabel: topology.kubernetes.io/zone

# Deployment 2
...
availabilityZoneSelector:
  enabled: true
  zone: "us-east-1b"

  # The node label to select on
  nodeZoneLabel: topology.kubernetes.io/zone

# Deployment 3
...
availabilityZoneSelector:
  enabled: true
  zone: "us-east-1c"

  # The node label to select on
  nodeZoneLabel: topology.kubernetes.io/zone
```

Change the `zone` to the correct availability zones present in your Kubernetes cluster. 

**Note:** Most Kubernetes cluster deployments will have the zone labeled on zones under the 
`topology.kubernetes.io/zone` label. If this is different for your deployment set `nodeZoneLabel` to the correct
value.

### Playground Mode

Use playground mode to easily test WarpStream without needing to first create a WarpStream account. See WarpStream's ["Hello World"](https://docs.warpstream.com/warpstream/getting-started/hello-world-using-kafka) to learn more.

Playground mode can also be used for testing the WarpStream Kubernetes deployment in local environments such as [kind][], [minikube][], or [Rancher Desktop][].

[kind]: https://kind.sigs.k8s.io/
[minikube]: https://minikube.sigs.k8s.io/docs/
[Rancher Desktop]: https://rancherdesktop.io/

**Warning**: In playground mode, the agent is configured to store all data in memory. This means that if the pod is restarted for any reason, the data will be lost.

Run in playground mode:
```shell
helm upgrade --install warpstream-agent warpstream/warpstream-agent \
    --set config.playground=true
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

### Using a different Kafka port

When deploying WarpStream agents it may be desired to change the kafka port that the agents listen on.

**Note:** This is only supported on chart version `0.15.59` or higher.

To change the port to `16500` for example, set the following values:

```yaml
# Set environment variable to tell the agent to listen on 16500.
extraEnv:
  - name: WARPSTREAM_KAFKA_PORT
    value: "16500"

# Update the container port to 16500 so Kubernetes can route traffic correctly.
containerPortKafka: 16500
```

If it is also desired to change the service or kafka service ports set the following values:

```yaml
# Optionally update the service port to 16500 if desired.
service:
  port: 16500

# Optionally update kafkaService port to 16500 if enabled.
kafkaService:
  port: 16500
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
| containerPortKafka | number | 9092 | The port on the container for Kafka |
| containerPortHTTP | number | 9092 | The port on the container for internal agent to agent communication |
| containerPortSchemaRegistry | number | 9092 | The port on the container for schema registry |
| service.type | string | `ClusterIP` | |
| service.loadBalancerClass | string | `` | Optional load balancer class |
| service.port | number | `9092` | |
| service.httpPort | number | `8080` | |
| service.schemaRegistryPort | number | `9094` | |
| service.labels | object | `{}` | Additional labels to add to the service |
| service.loadBalancerSourceRanges | list | `[]` | |
| service.perPod | bool | `false` | Create a unique service for each Kubernetes pod, typically only used when using Kong or Istio ingresses |
| headlessService.enabled | bool | `false` | Enable the headless service |
| kafkaService.enabled | bool | `false` | Enable the additional kafka service |
| kafkaService.type | string | `ClusterIP` | |
| kafkaService.loadBalancerClass | string | `` | Optional load balancer class |
| kafkaService.port | number | `9092` | |
| kafkaService.loadBalancerSourceRanges | list | `[]` | |
| bentoService.enabled | bool | `false` | Enable the additional bento service |
| bentoService.type | string | `ClusterIP` | |
| bentoService.loadBalancerClass | string | `` | Optional load balancer class |
| bentoService.port | number | `4195` | |
| bentoService.extraPorts | list | `[]` | Additional ports to add to the bento service |
| schemaRegistryService.enabled | bool | `false` | Enable the additional schema registry service |
| schemaRegistryService.type | string | `ClusterIP` | |
| schemaRegistryService.loadBalancerClass | string | `` | Optional load balancer class |
| schemaRegistryService.port | number | `9094` | |
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
| config.gracefulShutdownDuration | string | `300s` | The graceful shutdown period the WarpStream Agents will wait until shutting down. This is to allow clients enough time to disconnect gracefully |
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
| podSecurityContext | object | `{}` | specify a pod level security context (vs a container level with with `securityContext`) | 
| pdb.create | bool | `true` | Create a pod disruption budget |
| pdb.maxUnavailable | number | `1` | |
| serviceMonitor.enabled | bool | `false` | Enable creating a prometheus operator service monitor |
| prometheusRule.enabled | bool | `false` | Enable creating a prometheus operator prometheus rule |
| scrapeConfig.enabled | bool | `false` | Enable creating a prometheus operator scrape config |
| networkPolicy.enabled | bool | `false` | Create a network policy |
| networkPolicy.ingressRules | object | `{}` | The network policy ingress rules |
| networkPolicy.egressRules | object | `{}` | The network policy egress rules |

## Development

### Publishing a New Release

1. When applicable: Update `appVersion` in [`Chart.yaml`](./Chart.yaml) with the latest [release][].
1. When changing any Helm chart resources: Update `version` in [`Chart.yaml`](./Chart.yaml).

[release]: https://docs.warpstream.com/warpstream/reference/install-the-warpstream-agent
