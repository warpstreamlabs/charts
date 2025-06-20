# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.15.22] - 2025-06-30
- "helm template" APIVersions lacks Resource

## [0.15.15] - 2025-06-18
- Update WarpStream Agent to v666

## [0.15.14] - 2025-06-17
- Update WarpStream Agent to v665

## [0.15.13] - 2025-06-16
- Update WarpStream Agent to v664

## [0.15.12] - 2025-06-12
- Update WarpStream Agent to v663

## [0.15.11] - 2025-06-09
- Update WarpStream Agent to v662

## [0.15.10] - 2025-06-09
- Update WarpStream Agent to v661

## [0.15.9] - 2025-06-06
- Update WarpStream Agent to v660

## [0.15.8] - 2025-06-04
- Update WarpStream Agent to v659

## [0.15.7] - 2025-06-03
- Add `dnsConfig` variable to support changing the WarpStream Pod's dns configuration. See https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-dns-config for details.

## [0.15.6] - 2025-06-02
- Add ability to scrape [hosted prometheus endpoint](https://docs.warpstream.com/warpstream/byoc/monitor-the-warpstream-agents/hosted-prometheus-endpoint) with the prometheus operator [ScrapeConfig CRD](https://prometheus-operator.dev/docs/developer/scrapeconfig/)
- Fix Prometheus Service monitor to only scrape 1 service preventing duplicate metrics in prometheus

## [0.15.5] - 2025-05-30
- Update WarpStream Agent to v658

## [0.15.4] - 2025-05-22
- Update WarpStream Agent to v657

## [0.15.3] - 2025-05-20
- Update WarpStream Agent to v656

## [0.15.2] - 2025-05-20
- Update WarpStream Agent to v655

## [0.15.1] - 2025-05-15
- Update WarpStream Agent to v654

## [0.15.0] - 2025-05-13
- Add Network Policies template

## [0.14.20] - 2025-05-09
- Update WarpStream Agent to v653

## [0.14.19] - 2025-05-02
- Update WarpStream Agent to v650

## [0.14.18] - 2025-04-29
- Update WarpStream Agent to v649

## [0.14.17] - 2025-04-29
- Support `annotations` variable in all resources
  - For resources that have their own annotations field i.e `.Values.serviceAccount.annotations` the annotations will be merged together with the resource specific annotations taking priority
- Remove `deploymentAnnotations` variable as now it can be controlled via `annotations`.

## [0.14.16] - 2025-04-24
- Added `deploymentAnnotations` variable to set annotations of the deployment and statefulset

## [0.14.15] - 2025-04-18
- Update WarpStream Agent to v648

## [0.14.14] - 2025-04-16
- Added image pull secrets to test connection pods

## [0.14.13] - 2025-04-10
- Update WarpStream Agent to v647

## [0.14.12] - 2025-04-09
- Update WarpStream Agent to v646

## [0.14.11] - 2025-04-08
- Update WarpStream Agent to v645

## [0.14.10] - 2025-04-08
- Update WarpStream Agent to v644

## [0.14.9] - 2025-04-08
- Update WarpStream Agent to v643

## [0.14.8] - 2025-04-07
- Update WarpStream Agent to v642

## [0.14.7] - 2025-04-07
- Update WarpStream Agent to v641

## [0.14.6] - 2025-04-03
- Updating readme, dummy version bump so CI passes

## [0.14.5] - 2025-04-02
- Update WarpStream Agent to v640

## [0.14.4] - 2025-03-24
- Update WarpStream Agent to v639

## [0.14.3] - 2025-03-21
- Update WarpStream Agent to v638

## [0.14.2] - 2025-03-21
- Update WarpStream Agent to v637

## [0.14.1] - 2025-03-18
- Update WarpStream Agent to v636

## [0.14.0] - 2025-03-12
- Update WarpStream Agent to v635

## [0.13.101] - 2025-03-12
- Update WarpStream Agent to v634

## [0.13.100] - 2025-03-11
- Update WarpStream Agent to v633

## [0.13.99] - 2025-03-10
- Add `availabilityZoneSelector` to make it easier to deploy the chart into a single zone.

## [0.13.98] - 2025-03-10
- Update WarpStream Agent to v632

## [0.13.97] - 2025-03-07
- Fix test-connection.yaml for Kyverno policy compliance:
  - Add CPU and memory resource requests/limits for test pods
  - Add nodeSelector for architecture in test pods (configurable via values.yaml)
  - Add emptyDir volume to prevent hostPath Kyverno policy violations
  - Make all test pod settings configurable via values.yaml

## [0.13.95] - 2025-03-06
- Update WarpStream Agent to v630

## [0.13.94] - 2025-02-28
- Deprecate `apiKey` and `apiKeySecretKeyRef`
- Add `agentKey` and `agentKeySecretKeyRef`

## [0.13.93] - 2025-02-28
- Update WarpStream Agent to v629

## [0.13.92] - 2025-02-19
- Update WarpStream Agent to v628

## [0.13.91] - 2025-02-18
- Update WarpStream Agent to v627

## [0.13.90] - 2025-02-18
- Update WarpStream Agent to v626

## [0.13.89] - 2025-02-14
- Add support for low latancy clusters. Ref: https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/low-latency-clusters

## [0.13.88] - 2025-02-14
- Dummy release since the last release errored pushing to gh-pages

## [0.13.87] - 2025-02-12
- Update WarpStream Agent to v625

## [0.13.86] - 2025-02-10
- Update WarpStream Agent to v623

## [0.13.85] - 2025-02-06
- Update WarpStream Agent to v622

## [0.13.84] - 2025-02-05
- Update WarpStream Agent to v621

## [0.13.83] - 2025-02-03
- Update WarpStream Agent to v620

## [0.13.82] - 2025-02-02
- Update WarpStream Agent to v619

## [0.13.81] - 2025-01-31
- Update WarpStream Agent to v618

## [0.13.80] - 2025-01-27
- Add support for `loadBalancerSourceRanges` in services.

## [0.13.79] - 2025-01-24
- Update WarpStream Agent to v616.

## [0.13.78] - 2025-01-24
- Don't fall back to using a secret secret when `configMapEnabled` is set to false.
  - In the past, some deployment combinations would cause pods to not run due to missing secrets.
  - For example if `configMapEnabled` was false, and `config.apiKeySecretKeyRef` was used, the secret `{{ include "warpstream-agent.secretName" . }}` would not exist which would prevent pods from starting.
  - Users that were relying on this functionality should switch to `extraEnvFrom` that was added in `0.13.76`, as the previous functionaliy was not intended behavior.
- Document env variables that should be set if `configMapEnabled` is set to false

## [0.13.77] - 2025-01-24
- Update WarpStream Agent to v615.

## [0.13.76] - 2025-01-22

- Update WarpStream Agent to v614.
- Add native support for agent groups https://docs.warpstream.com/warpstream/byoc/advanced-agent-deployment-options/agent-groups
- Add value array `extraEnvFrom` to add more items to the `envFrom` field.

## [0.13.75] - 2025-01-22

- Update WarpStream Agent to v613.

## [0.13.74] - 2025-01-16

- Update WarpStream Agent to v612.

## [0.13.73] - 2025-01-15

- Add the ability to override the advertised hostname when running a StatefulSet

## [0.13.72] - 2025-01-10

- Update WarpStream Agent to v611.

## [0.13.71] - 2025-01-08

- Update WarpStream Agent to v610.

## [0.13.70] - 2024-12-23

- Add the ability to create services per pod to expose each pod outside of the cluster

## [0.13.69] - 2024-12-19

- Make certificates first class variables so it is easier to configure without having to use volumes and env variables

## [0.13.68] - 2024-12-19

- Update WarpStream Agent to v609.

## [0.13.67] - 2024-12-18

- Update WarpStream Agent to v608.

## [0.13.66] - 2024-12-18

- Update WarpStream Agent to v607.
- Fix volumes and volume mounts not rendering when in playground mode

## [0.13.65] - 2024-12-12

- Update WarpStream Agent to v606.

## [0.13.64] - 2024-12-11

- Update WarpStream Agent to v605.

## [0.13.62] - 2024-12-09

- Update WarpStream Agent to v604.

## [0.13.61] - 2024-12-05

- Allow adding `labels` to the service

## [0.13.60] - 2024-12-02

### Added

- Added an optional dedicated Kafka service to make it easier to expose only Kafka externally.

## [0.13.59] - 2024-12-02

### Added

- Update WarpStream Agent to v603.

## [0.13.58] - 2024-11-29

### Added

- Add clarifying comment in values.yaml

## [0.13.57] - 2024-11-25

### Added

- Update WarpStream Agent to v602.

## [0.13.56] - 2024-11-22

### Added

- Make the ConfigMap optional.
- Add affinity for diagnose pods.

## [0.13.55] - 2024-11-21

### Added

- Update WarpStream Agent to v601.

## [0.13.54] - 2024-11-20

### Added

- Expose port 9094 for playground and for Schema Registry.

## [0.13.53] - 2024-11-20

### Added

- Update WarpStream Agent to v600.

## [0.13.52] - 2024-11-8

### Added

- Update WarpStream Agent to v598.

## [0.13.48] - 2024-11-6

### Added

- Update WarpStream Agent to v597.

## [0.13.47] - 2024-11-1

### Added

- Update WarpStream Agent to v596.

## [0.13.46] - 2024-10-30

### Added

- Update WarpStream Agent to v595.

## [0.13.45] - 2024-10-29

### Added

- Fix typo in chart.

## [0.13.44] - 2024-10-29

### Added

- Make sure there is only one replica in playground mode.

## [0.13.43] - 2024-10-29

### Added

- Remove need for unnecessary configuration options in playground mode.

## [0.13.42] - 2024-10-28

### Added

- Update WarpStream Agent to v594.

## [0.13.41] - 2024-10-29

### Added

- Fix bug where unnecessary configuration was required in playground mode.

## [0.13.40] - 2024-10-27

### Added

- Update WarpStream Agent to v593.

## [0.13.39] - 2024-10-23

### Added

- Update WarpStream Agent to v592.

## [0.13.38] - 2024-10-22

### Added

- Update WarpStream Agent to v591.

## [0.13.37] - 2024-10-19

### Added

- Remove limit on ephemeral storage in chart as its unnecessary.

## [0.13.36] - 2024-10-17

### Added

- Update WarpStream Agent to v590.

## [0.13.35] - 2024-10-16

### Added

- Update WarpStream Agent to v589.

## [0.13.34] - 2024-10-11

### Added

- Update WarpStream Agent to v588.

## [0.13.33] - 2024-10-08

### Added

- Increase default CPU requests from 2 to 4.

## [0.13.32] - 2024-09-27

### Added

- Update WarpStream Agent to v587.

## [0.13.31] - 2024-09-25

### Added

- Update WarpStream Agent to v586.

## [0.13.30] - 2024-09-24

### Added

- Update WarpStream Agent to v585.

## [0.13.29] - 2024-09-23

### Added

- Update WarpStream Agent to v584.

## [0.13.28] - 2024-09-18

### Added

- Update WarpStream Agent to v583.
  
## [0.13.27] - 2024-09-18

### Added

- Update WarpStream Agent to v582.

## [0.13.26] - 2024-09-12

### Added

- Update WarpStream Agent to v581.

## [0.13.25] - 2024-09-11

### Added

- Update WarpStream Agent to v580.

## [0.13.24] - 2024-09-09

### Added

- Update WarpStream Agent to v579.

## [0.13.23] - 2024-09-04

### Added

- Add a liveness check.

## [0.13.22] - 2024-09-03

### Added

- Fix a regression introduced in 0.13.19 that was preventing users to use a cpu request in millicores.

### Added

- Update WarpStream Agent to v578.

## [0.13.20] - 2024-08-27

### Added

- Tune the auto-scaler to be less aggressive (upscale slightly slower, downscale *much* slower).

## [0.13.19] - 2024-08-27

### Added

- Enforce at least 4GiB of RAM per CPU.

## [0.13.18] - 2024-08-27

### Added

- Enable auto-scaling by default.

## [0.13.17] - 2024-08-27

### Added

- Throw error if any required configuration options are empty.

## [0.13.16] - 2024-08-25

### Added

- Update WarpStream Agent to v577.

## [0.13.15] - 2024-08-22

### Added

- Update WarpStream Agent to v576.

## [0.13.14] - 2024-08-18

### Added

- Update WarpStream Agent to v575.

## [0.13.13] - 2024-08-15

### Added

- Update WarpStream Agent to v574.

## [0.13.12] - 2024-08-14

### Added

- Request 100MiB of ephemeral storage on each agent (because kubernetes counts some logs it emits
  about the agent container against its ephemeral storage).
- Upgrade WarpStream Agent version to v573

## [0.13.12] - 2024-08-07

### Added

- Request 100MiB of ephemeral storage on each agent (because kubernetes counts some logs it emits
  about the agent container against its ephemeral storage).

## [0.13.11] - 2024-08-06

### Added

- Upgrade WarpStream Agent version to v572

## [0.13.10] - 2024-08-06

### Added

- Fix ServiceMonitor jobLabel, updating to an existing Service label

## [0.13.9] - 2024-08-02

### Added

- Upgrade WarpStream Agent version to v571

## [0.13.8] - 2024-08-01

### Added

- Change default values for deployment rolling update strategy.

## [0.13.7] - 2024-07-31

### Added

- Enable pod disruption budget by default with reasonable configuration.

## [0.13.6] - 2024-07-18

### Added

- Make apiKey optional and disable replicas when running agent in playground mode.

## [0.13.5] - 2024-07-17

### Added

- update warpstream agent version to v570

## [0.13.4] - 2024-07-17

### Added

- Allow manual override of GOMAXPROCS env var with .Values.goMaxProcs

## [0.13.3] - 2024-07-11

### Added

- Make podLabels optional, from version 1.13.1 it it failed if it wasn't set at least one label.

## [0.13.2] - 2024-07-05

### Added

- update warpstream agent version to v569

## [0.13.1] - 2024-07-05

### Added

- Fixes the podLabels that was not used anymore.

## [0.13.0] - 2024-07-04

### Added

- Added the ability to specify arbitrary volumes and volume mounts in the pods.

## [0.12.26] - 2024-07-03

### Added

- update warpstream agent version to v568

## [0.12.25] - 2024-06-20

### Added

- make `terminationGracePeriodSeconds` customizable

## [0.12.24] - 2024-06-19

### Added

- update warpstream agent version to v567

## [0.12.23] - 2024-06-05

### Added

- update warpstream agent version to v566

## [0.12.22] - 2024-06-05

### Added

- update warpstream agent version to v565

## [0.12.21] - 2024-06-05

### Added

- deployment strategy, topologySpreadConstraints, revisionHistoryLimit, customScheduler

## [0.12.20] - 2024-05-26

### Added

- update warpstream agent version to v564

## [0.12.19] - 2024-05-19

### Added

- update warpstream agent version to v562

## [0.12.18] - 2024-05-19

### Added

- update warpstream agent version to v561

## [0.12.17] - 2024-05-19

### Added

- update warpstream agent version to v560

## [0.12.16] - 2024-05-13

### Added

- update warpstream agent version to v559

## [0.12.14] - 2024-05-10

### Added

- update warpstream agent version to v558

## [0.12.13] - 2024-05-09

### Added

- update warpstream agent version to v557

## [0.12.12] - 2024-05-09

### Added

- update warpstream agent version to v556

## [0.12.11] - 2024-05-08

### Added

- update warpstream agent version to v555

## [0.12.10] - 2024-05-04

### Added

- update warpstream agent version to v554

## [0.12.9] - 2024-04-30

### Added

- update warpstream agent version to v553

## [0.12.8] - 2024-04-29

### Added

- update warpstream agent version to v552

## [0.12.7] - 2024-04-26

### Added

- update warpstream agent version to v551

## [0.12.6] - 2024-04-23

### Added

- update warpstream agent version to v550

## [0.12.5] - 2024-04-22

### Added

- update warpstream agent version to v549

## [0.12.4] - 2024-04-17

### Added

- update warpstream agent version to v548

## [0.12.3] - 2024-04-11

### Added

- update warpstream agent version to v547

## [0.10.18] - 2024-04-04

### Added

- update warpstream agent version to v545

## [0.10.17] - 2024-04-03

### Added

- various fixes
- automountServiceAccountToken configuration moved to service account from pod template

## [0.10.16] - 2024-04-02

### Added

- update warpstream agent version to v544

## [0.10.15] - 2024-03-29

### Added

- update warpstream agent version to v543

## [0.10.14] - 2024-03-26

### Added

- update warpstream agent version to v542

## [0.10.12] - 2024-03-18

### Added

- update warpstream agent version to v540

## [0.10.11] - 2024-03-15

### Added

- update warpstream agent version to v539

## [0.10.10] - 2024-03-13

### Added

- Prometheus rule template added

## [0.10.9] - 2024-03-6

### Added

- automatically roll deployments on config change
- added checksum to deployment for configmap and secret
- update warpstream agent version to v538
