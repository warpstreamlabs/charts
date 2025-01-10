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
    --set config.apiKey="$YOUR_API_KEY" \
    --set config.region="$YOUR_CONTROL_PLANE_REGION" \
    --set config.virtualClusterID="$YOUR_VIRTUAL_CLUSTER_ID"
```

The chart creates a Kubernetes Secret for the Agent API key. You can also create a secret manually and set `config.secretName` to the secret's name (the secret key field must be `apikey`).

As an alternative to supplying the configuration parameters as arguments, you can create a supplemental YAML file containing your specific config parameters. Any parameters not specified in this file will default to those set in [values.yaml](values.yaml).

1. Create an empty `warpstream-values.yaml` file
2. Edit the file with your specific parameters:

```yaml
config:
  bucketURL: <WARPSTREAM_BUCKET_URL>
  apiKey: <WARPSTREAM_AGENT_APIKEY>
  virtualClusterID: <WARPSTREAM_VIRTUAL_CLUSTER_ID>
  region: <WARPSTREAM_CLUSTER_REGION>
```

3. Install or upgrade the WarpStream Helm chart using your custom yaml file:

```shell
helm upgrade --install warpstream-agent warpstream/warpstream-agent -f warpstream-values.yaml
```

### Upgrading

To upgrade the deployment:

```shell
helm repo update
helm upgrade warpstream-agent warpstream/warpstream-agent --reuse-values
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


## Other Deployment Options

### LoadBalancer Service
The stateless nature of the WarpStream agents allows them to be deployed behind a network load balancer using `type: LoadBalancer` in your Service configuration. See the [Kubernetes Service documentation](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) for details.

Update your Helm chart configuration with these parameters:

```yaml
service:
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
service:
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


## All configuration options

Refer to the [Agent Configuration Reference](https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/agent-configuration) for available configuration values.


## Development

### Publishing a new release

1. When applicable: Update `appVersion` in [`Chart.yaml`](./Chart.yaml) with the latest [release][].
1. When changing any Helm chart resources: Update `version` in [`Chart.yaml`](./Chart.yaml).

[release]: https://docs.warpstream.com/warpstream/reference/install-the-warpstream-agent
