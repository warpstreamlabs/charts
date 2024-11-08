{{/*
Expand the name of the chart.
*/}}
{{- define "warpstream-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "warpstream-agent.fullname" -}}
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
{{- define "warpstream-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "warpstream-agent.labels" -}}
helm.sh/chart: {{ include "warpstream-agent.chart" . }}
{{ include "warpstream-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "warpstream-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "warpstream-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Secret Name
*/}}
{{- define "warpstream-agent.secretName" -}}
{{- if .Values.config.secretName }}
{{- .Values.config.secretName }}
{{- else }}
{{- printf "%s-apikey" (include "warpstream-agent.fullname" .) -}}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "warpstream-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "warpstream-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for Horizontal Pod Autoscaler.
*/}}
{{- define "warpstream-agent.hpa.apiVersion" -}}
{{- if $.Capabilities.APIVersions.Has "autoscaling/v2/HorizontalPodAutoscaler" }}
{{- print "autoscaling/v2" }}
{{- else if $.Capabilities.APIVersions.Has "autoscaling/v2beta2/HorizontalPodAutoscaler" }}
{{- print "autoscaling/v2beta2" }}
{{- else }}
{{- print "autoscaling/v2beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for podDisruptionBudget.
*/}}
{{- define "warpstream-agent.pdb.apiVersion" -}}
{{- if $.Values.pdb.apiVersion }}
{{- print $.Values.pdb.apiVersion }}
{{- else if $.Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget" }}
{{- print "policy/v1" }}
{{- else }}
{{- print "policy/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Convert units like 4GiB and 2000MiB to bytes.
*/}}
{{- define "convertToBytes" -}}
{{- $memory := . | upper | trimSuffix "B" | trimSuffix "I" -}}
{{- $bytes := 0}}
{{- if hasSuffix "G" $memory -}}
{{- $value := trimSuffix "G" $memory | int -}}
{{- $bytes = mul $value 1073741824 -}}
{{- else if hasSuffix "M" $memory -}}
{{- $value := trimSuffix "M" $memory | int -}}
{{- $bytes = mul $value 1048576 -}}
{{- else if hasSuffix "K" $memory -}}
{{- $value := trimSuffix "K" $memory | int -}}
{{- $bytes = mul $value 1024 -}}
{{- else -}}
{{- $bytes = . | int -}}
{{- end -}}
{{- $bytes -}}
{{- end -}}

{{/*
Convert CPU requests to millicores integers. 
Let's take a few examples:
 - if the cpu request is "900m", it will return 900
 - if the cpu request is 0.7, it will return 700
 - if the cpu request is 4, it will return 4000
*/}}
{{- define "convertToMillicores" -}}
{{- $cpu := . | toString -}}
{{- $cpuMillicores := 0}}
{{- if hasSuffix "m" $cpu -}}
{{- $value := trimSuffix "m" $cpu | int -}}
{{- $cpuMillicores = $value -}}
{{- else -}}
{{- $cpuMillicores = mulf . 1000 | int -}}
{{- end -}}
{{- $cpuMillicores -}}
{{- end -}}

{{/*
Return the deployment kind to use
*/}}
{{- define "warpstream-agent.deploymentKind" -}}
{{- if $.Values.deploymentKind }}
{{- print $.Values.deploymentKind }}
{{- else }}
{{- print "Deployment" }}
{{- end }}
{{- end }}
