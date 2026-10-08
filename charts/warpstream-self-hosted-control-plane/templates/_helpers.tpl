{{/*
Expand the name of the chart.
*/}}
{{- define "wscp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wscp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wscp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wscp.labels" -}}
helm.sh/chart: {{ include "wscp.chart" . }}
{{ include "wscp.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wscp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wscp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wscp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wscp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name and key of the Secret holding the configuration file.
*/}}
{{- define "wscp.configSecretName" -}}
{{- default (printf "%s-config" (include "wscp.fullname" .)) .Values.config.existingSecret }}
{{- end }}

{{- define "wscp.configSecretKey" -}}
{{- if .Values.config.existingSecret }}
{{- .Values.config.existingSecretKey }}
{{- else -}}
config.toml
{{- end }}
{{- end }}

{{/*
Name and key of the Secret holding the license key.
*/}}
{{- define "wscp.licenseSecretName" -}}
{{- default (printf "%s-license" (include "wscp.fullname" .)) .Values.license.existingSecret }}
{{- end }}

{{- define "wscp.licenseSecretKey" -}}
{{- if .Values.license.existingSecret }}
{{- .Values.license.existingSecretKey }}
{{- else -}}
license-key
{{- end }}
{{- end }}

{{/*
Fail early on missing required values.
*/}}
{{- define "wscp.validate" -}}
{{- if not .Values.image.repository }}
{{- fail "image.repository is required" }}
{{- end }}
{{- if not .Values.image.tag }}
{{- fail "image.tag is required: pin a control plane release, e.g. 2026-w41" }}
{{- end }}
{{- if lt (int .Values.replicas) 3 }}
{{- fail "replicas must be at least 3" }}
{{- end }}
{{- if and (not .Values.config.clusterConf) (not .Values.config.existingSecret) }}
{{- fail "one of config.clusterConf or config.existingSecret is required" }}
{{- end }}
{{- if not .Values.config.snapshotBucketURL }}
{{- fail "config.snapshotBucketURL is required" }}
{{- end }}
{{- if and (not .Values.license.key) (not .Values.license.existingSecret) }}
{{- fail "one of license.key or license.existingSecret is required" }}
{{- end }}
{{- end }}
