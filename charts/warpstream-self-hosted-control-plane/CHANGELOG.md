# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-10-15
- Document Kafka ACLs (`acls_enabled`, `acl_shadowing_enabled`, `external_superusers`) and configuring multiple virtual clusters.
- Add `tls` to serve the agent API over HTTPS on `ports.https` (`8443`), and `internalTLS` for TLS, mTLS and SPIFFE checks between replicas.

## [0.1.0] - 2026-10-06
- Initial release of the WarpStream self-hosted control plane chart (AWS, DynamoDB).
