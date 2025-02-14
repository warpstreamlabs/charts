#!/bin/bash
set -e
set -o pipefail

# Test for setting the apiKey via Helm
set +e
read -r -d '' ci_test_apikey_buildin << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east-1"
  apiKey: "${DefaultVirtualClusterAgentKeySecret}"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 1
    memory: 4Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 4Gi
EOM
set -e

echo "${ci_test_apikey_buildin}" | envsubst > charts/warpstream-agent/ci/apikey-buildin-values.yaml

# Test for setting the apiKey via external secret
set +e
read -r -d '' ci_test_apikey_external << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east-1"
  apiKeySecretKeyRef:
    name: external-secret
    key: agentkey

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 1
    memory: 4Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 4Gi
EOM
set -e

echo "${ci_test_apikey_external}" | envsubst > charts/warpstream-agent/ci/apikey-external-values.yaml

# Test for using agent groups
set +e
read -r -d '' ci_test_apikey_agent_group << EOM
config:
  bucketURL: "mem://mem_bucket"
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east-1"
  apiKey: "${DefaultVirtualClusterAgentKeySecret}"
  agentGroup: "my-group"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 1
    memory: 4Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 4Gi
EOM
set -e

echo "${ci_test_apikey_agent_group}" | envsubst > charts/warpstream-agent/ci/apikey-agent-group-values.yaml

# Test for using s3 express
set +e
read -r -d '' ci_test_apikey_s3express << EOM
config:
  virtualClusterID: "${DefaultVirtualClusterID}"
  region: "us-east-1"
  apiKey: "${DefaultVirtualClusterAgentKeySecret}"
  ingestionBucketURL: "warpstream_multi://mem://mem_bucket<>mem://mem_bucket<>mem://mem_bucket"
  compactionBucketURL: "mem://mem_bucket"

# overriding resources so it fits on a runner
resources:
  requests:
    cpu: 1
    memory: 4Gi
    # we do not need the disk space, but Kubernetes will count some logs that it emits
    # about our containers towards our containers ephemeral usage and if we requested
    # 0 storage we could end up getting evicted unnecessarily when the node is under disk pressure.
    ephemeral-storage: "100Mi"
  limits:
    memory: 4Gi
EOM
set -e

echo "${ci_test_apikey_s3express}" | envsubst > charts/warpstream-agent/ci/apikey-agent-group-values.yaml