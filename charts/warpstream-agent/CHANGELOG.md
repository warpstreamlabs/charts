# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
