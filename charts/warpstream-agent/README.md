# WarpStream Agent Helm chart

The official Helm chart for the [Warpstream agent for Kubernetes][agent-k8s].

[agent-k8s]: ===CHART_DOC_URL===

## Getting started

### Prerequisites

This chart requires Helm v3.6 or later.

### Install the latest stable release

```shell
helm repo add warpstream https://warpstreamlabs.github.io/charts
helm repo update
helm upgrade --install warpstream-agent warpstream/warpstream-agent \
    --set config.bucketURL="$YOUR_OBJECT_STORE" \
    --set config.apiKey="$YOUR_API_KEY" \
    --set config.region="$YOUR_CONTROL_PLANE_REGION" \
    --set config.virtualClusterID="$YOUR_VIRTUAL_CLUSTER_ID"
```

To learn what values to set for those config variables, look at our documentation
for [configuring the WarpStream Agents for production](https://docs.warpstream.com/warpstream/how-to/configure-the-warpstream-agent-for-production).

### Upgrade an existing release

```shell
helm repo update
helm upgrade  warpstream-agent warpstream/warpstream-agent --reuse-values
```

### Customize

See [`values.yaml`](./values.yaml).

### Install from source

``` shell
git clone https://github.com/warpstreamlabs/charts
cd charts/warpstream-agent
helm upgrade --install warpstream-agent . \
    --set config.bucketURL="$YOUR_OBJECT_STORE" \
    --set config.apiKey="$YOUR_API_KEY" \
    --set config.region="$YOUR_CONTROL_PLANE_REGION"
    --set config.virtualClusterID="$YOUR_VIRTUAL_CLUSTER_ID"
```

## Development

### Testing locally

Bootstrap a Kubernetes cluster locally, for example with [kind][].

```shell
helm upgrade --install warpstream-agent . --set config.playground=true
helm test warpstream-agent
kubectl logs warpstream-agent-diagnose-connection
```

Or manually diagnose connection with
```shell
kubectl port-forward svc/warpstream-agent 9092 &
docker run --net=host public.ecr.aws/warpstream-labs/warpstream_agent_linux_amd64 \
    kcmd -bootstrap-host localhost -type diagnose-connection
```

[kind]: https://kind.sigs.k8s.io/

### Publishing a new release

1. When applicable: Update `appVersion` in [`Chart.yaml`](./Chart.yaml) with the latest [release][].
1. When changing any Helm chart resources: Update `version` in [`Chart.yaml`](./Chart.yaml).

[release]: https://docs.warpstream.com/warpstream/reference/install-the-warpstream-agent
