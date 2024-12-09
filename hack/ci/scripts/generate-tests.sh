#!/bin/bash
set -e
set -o pipefail

set +e
read -r -d '' ci_test_apikey_buildin << EOM
config:
    bucketURL: "mem://mem_bucket"
    virtualClusterID: "${DefaultVirtualClusterID}"
    region: "us-east-1"
    apiKey: "${DefaultVirtualClusterAgentKeySecret}"
EOM
set -e

echo "${ci_test_apikey_buildin}" | envsubst > charts/warpstream-agent/ci/apikey-buildin.yaml

set +e
read -r -d '' ci_test_apikey_buildin << EOM
config:
    bucketURL: "mem://mem_bucket"
    virtualClusterID: "${DefaultVirtualClusterID}"
    region: "us-east-1"
    apiKeySecretKeyRef:
        name: external-secret
        key: agentkey
EOM
set -e

echo "${ci_test_apikey_buildin}" | envsubst > charts/warpstream-agent/ci/apikey-external.yaml