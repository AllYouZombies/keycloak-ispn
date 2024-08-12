{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak-ispn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "keycloak-ispn.fullname" -}}
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
{{- define "keycloak-ispn.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "keycloak-ispn.labels" -}}
helm.sh/chart: {{ include "keycloak-ispn.chart" . }}
{{ include "keycloak-ispn.kc.selectorLabels" . }}
{{ include "keycloak-ispn.ispn.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels for ISPN
*/}}
{{- define "keycloak-ispn.ispn-labels" -}}
helm.sh/chart: {{ include "keycloak-ispn.chart" . }}
{{ include "keycloak-ispn.kc.selectorLabels" . }}
{{ include "keycloak-ispn.ispn.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "keycloak-ispn.kc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak-ispn.name" . }}-keycloak
app.kubernetes.io/instance: {{ .Release.Name }}-keycloak
{{- end }}
{{- define "keycloak-ispn.ispn.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak-ispn.name" . }}-ispn
app.kubernetes.io/instance: {{ .Release.Name }}-ispn
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "keycloak-ispn.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keycloak-ispn.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
