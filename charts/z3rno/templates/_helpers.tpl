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
Beat fullname (Celery beat scheduler — drives the audit_drain periodic task).
*/}}
{{- define "z3rno.beat.fullname" -}}
{{- printf "%s-beat" (include "z3rno.fullname" .) }}
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
Phase F slice 7 — multi-region pod labels.
Adds ``z3rno.region`` when multiRegion is enabled. Empty when off so
existing single-region deploys render byte-identically.
*/}}
{{- define "z3rno.regionLabels" -}}
{{- if .Values.multiRegion.enabled }}
z3rno.region: {{ .Values.multiRegion.region | quote }}
{{- end }}
{{- end }}

{{/*
Phase F slice 7 — topologySpreadConstraints fragment.
Spreads replicas across the listed zones with maxSkew=1 so a zonal
outage doesn't take out an entire region's pods.
*/}}
{{- define "z3rno.topologySpread" -}}
{{- if and .Values.multiRegion.enabled .Values.multiRegion.zones }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        {{- include "z3rno.selectorLabels" . | nindent 8 }}
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

{{/*
v0.19.10 — imagePullSecrets fragment.

Emits the full ``imagePullSecrets:`` block (key + entries) when
either of these is true:
  * ``Values.imagePullSecrets`` has entries.
  * ``Values.imagePullSecret.create`` is true → references the
    chart-rendered ``<release>-ghcr-pull`` secret.

Renders nothing (no key) when neither path is active so the parent
``spec:`` stays clean. Callers indent with ``| nindent 6``.
*/}}
{{- define "z3rno.imagePullSecrets" -}}
{{- $secrets := list -}}
{{- if .Values.imagePullSecret.create -}}
  {{- $secrets = append $secrets (dict "name" (printf "%s-ghcr-pull" (include "z3rno.fullname" .))) -}}
{{- end -}}
{{- range .Values.imagePullSecrets -}}
  {{- $secrets = append $secrets . -}}
{{- end -}}
{{- if $secrets -}}
imagePullSecrets:
{{ toYaml $secrets | indent 2 }}
{{- end -}}
{{- end }}
