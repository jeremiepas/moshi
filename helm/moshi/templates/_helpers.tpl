{{- /*
Expand the name of the chart.
*/}}
{{- define "moshi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- /*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "moshi.fullname" -}}
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

{{- /*
Create chart name and version as used by the chart label.
*/}}
{{- define "moshi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- /*
Common labels
*/}}
{{- define "moshi.labels" -}}
helm.sh/chart: {{ include "moshi.chart" . }}
{{ include "moshi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- /*
Selector labels
*/}}
{{- define "moshi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moshi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- /*
Create the name of the service account to use
*/}}
{{- define "moshi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "moshi.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- /*
Backend labels
*/}}
{{- define "moshi.backendLabels" -}}
{{ include "moshi.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{- /*
WebUI labels
*/}}
{{- define "moshi.webuiLabels" -}}
{{ include "moshi.labels" . }}
app.kubernetes.io/component: webui
{{- end }}

{{- /*
Backend selector labels
*/}}
{{- define "moshi.backendSelectorLabels" -}}
{{ include "moshi.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{- /*
WebUI selector labels
*/}}
{{- define "moshi.webuiSelectorLabels" -}}
{{ include "moshi.selectorLabels" . }}
app.kubernetes.io/component: webui
{{- end }}
