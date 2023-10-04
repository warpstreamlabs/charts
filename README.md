## WarpStream Helm Charts

This repository contains WarpStream's official Helm charts and automatically
publishes them to the Helm repo, located at [warpstreamlabs.github.io/charts](https://warpstreamlabs.github.io/charts).

This project relies on [chart-releaser Action](https://github.com/helm/chart-releaser-action)
to package/update/publish Helm charts. When new commits are pushed on `main`,
[Chart Releaser](https://github.com/helm/chart-releaser) scans folders under `charts/`
for new versions and creates the corresponding GitHub Releases.

For publishing a new Chart release, push a commit incrementing `version` in `Chart.yaml`.
