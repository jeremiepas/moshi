{{/*
Expand the name of the chart.
*/}}
{{- define "moshi.observability.name" -}}
{{- include "moshi.fullname" . }}-observability
{{- end }}

{{/*
Create the name of the service account to use for observability components.
*/}}
{{- define "moshi.observability.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "moshi.observability.name" . ) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
observability selector labels
*/}}
{{- define "moshi.observability.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moshi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: observability
{{- end }}

{{/*
Prometheus labels
*/}}
{{- define "moshi.prometheus.labels" -}}
{{ include "moshi.labels" . }}
app.kubernetes.io/component: prometheus
{{- end }}

{{/*
Prometheus selector labels
*/}}
{{- define "moshi.prometheus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "moshi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: prometheus
{{- end }}

{{/*
Prometheus full name
*/}}
{{- define "moshi.prometheus.fullname" -}}
{{- include "moshi.fullname" . }}-prometheus
{{- end }}

{{/*
Grafana full name
*/}}
{{- define "moshi.grafana.fullname" -}}
{{- include "moshi.fullname" . }}-grafana
{{- end }}

{{/*
Sidecar resource name for metrics exporter
*/}}
{{- define "moshi.metricsSidecar.fullname" -}}
{{- include "moshi.fullname" . }}-metrics-sidecar
{{- end }}