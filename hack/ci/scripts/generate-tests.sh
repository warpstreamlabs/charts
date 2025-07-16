#!/bin/bash
set -e
set -o pipefail

# Test for setting the deprecated apiKey via Helm
set +e
read -r -d '' ci_test_apikey_buildin << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  apiKey: "${DefaultVirtualClusterAgentKeySecret}"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_apikey_buildin}" | envsubst > charts/warpstream-agent/ci/apikey-buildin-values.yaml

# Test for setting the agentKey via Helm
set +e
read -r -d '' ci_test_agentkey_buildin << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  agentKey: "${DefaultVirtualClusterAgentKeySecret}"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_agentkey_buildin}" | envsubst > charts/warpstream-agent/ci/agentkey-buildin-values.yaml

# Test for setting the deprecated apiKey via external secret
set +e
read -r -d '' ci_test_apikey_external << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  apiKeySecretKeyRef:
    name: external-secret
    key: agentkey

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_apikey_external}" | envsubst > charts/warpstream-agent/ci/apikey-external-values.yaml

# Test for setting the agentKey via external secret
set +e
read -r -d '' ci_test_agentkey_external << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  agentKeySecretKeyRef:
    name: external-secret
    key: agentkey

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_agentkey_external}" | envsubst > charts/warpstream-agent/ci/agentkey-external-values.yaml

# Test for using agent groups
set +e
read -r -d '' ci_test_agentkey_agent_group << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  agentKey: "${DefaultVirtualClusterAgentKeySecret}"
  agentGroup: "my-group"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_agentkey_agent_group}" | envsubst > charts/warpstream-agent/ci/agentkey-agent-group-values.yaml

# Test for using s3 express
set +e
read -r -d '' ci_test_agentkey_s3express << EOM
config:
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  agentKey: "${DefaultVirtualClusterAgentKeySecret}"
  ingestionBucketURL: "warpstream_multi://mem://mem_bucket<>mem://mem_bucket<>mem://mem_bucket"
  compactionBucketURL: "mem://mem_bucket"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_agentkey_s3express}" | envsubst > charts/warpstream-agent/ci/agentkey-s3express-values.yaml

# Test for prometheus operator scraping
set +e
read -r -d '' ci_test_prometheus_scrape << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east1"
  agentKeySecretKeyRef:
    name: external-secret
    key: agentkey

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi

serviceMonitor:
  enabled: true

scrapeConfig:
  enable: true
  passwordKeyRef:
    name: external-secret
    key: agentkey
EOM
set -e

echo "${ci_test_prometheus_scrape}" | envsubst > charts/warpstream-agent/ci/prometheus-scrape-values.yaml

# Test for setting the metadataURL instead of region
set +e
read -r -d '' ci_test_metadataURL << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  metadataURL: "https://metadata.default.us-east1.gcp.warpstream.com"
  agentKey: "${DefaultVirtualClusterAgentKeySecret}"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 2Gi

# Test resource settings
test:
  resources:
    requests:
      cpu: 1m
      memory: 128Mi
    limits:
      cpu: 100m
      memory: 256Mi
EOM
set -e

echo "${ci_test_metadataURL}" | envsubst > charts/warpstream-agent/ci/metadataURL-values.yaml
