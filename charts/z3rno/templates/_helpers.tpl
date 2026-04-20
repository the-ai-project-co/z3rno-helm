{{/*
Expand the name of the chart.
*/}}
{{- define "z3rno.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "z3rno.fullname" -}}
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
{{- define "z3rno.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "z3rno.labels" -}}
helm.sh/chart: {{ include "z3rno.chart" . }}
{{ include "z3rno.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "z3rno.selectorLabels" -}}
app.kubernetes.io/name: {{ include "z3rno.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "z3rno.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "z3rno.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Server fullname.
*/}}
{{- define "z3rno.server.fullname" -}}
{{- printf "%s-server" (include "z3rno.fullname" .) }}
{{- end }}

{{/*
Worker fullname.
*/}}
{{- define "z3rno.worker.fullname" -}}
{{- printf "%s-worker" (include "z3rno.fullname" .) }}
{{- end }}

{{/*
Valkey fullname.
*/}}
{{- define "z3rno.valkey.fullname" -}}
{{- printf "%s-valkey" (include "z3rno.fullname" .) }}
{{- end }}

{{/*
Secret name to use (existing or chart-managed).
*/}}
{{- define "z3rno.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- include "z3rno.fullname" . }}
{{- end }}
{{- end }}

{{/*
Redis/Valkey URL.
If externalRedis is enabled, build from external config.
Otherwise, use bundled Valkey service.
*/}}
{{- define "z3rno.redisUrl" -}}
{{- if .Values.externalRedis.enabled }}
{{- if .Values.secrets.redisUrl }}
{{- .Values.secrets.redisUrl }}
{{- else }}
{{- printf "redis://%s:%d/0" .Values.externalRedis.host (int .Values.externalRedis.port) }}
{{- end }}
{{- else }}
{{- printf "redis://%s:%d/0" (include "z3rno.valkey.fullname" .) (int .Values.valkey.port) }}
{{- end }}
{{- end }}
