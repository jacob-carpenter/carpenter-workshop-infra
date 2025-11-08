{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.app.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.app.name }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.podLabels.environment | default "prod" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ .Values.app.name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "common.imagePullSecrets" -}}
{{- if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ .name }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate full image name
*/}}
{{- define "common.image" -}}
{{- if .Values.image.registry }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository .Values.image.tag }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}
{{- end }}

{{- define "common.sharedAlb.groupName" -}}
{{- .Values.sharedAlb.groupName | default "carpenter-workshop-shared" -}}
{{- end }}

{{- define "common.sharedAlb.certificateArn" -}}
{{- .Values.sharedAlb.certificateArn | default "arn:aws:acm:us-east-1:740474257663:certificate/88ca8003-9a3d-46e4-9331-bc68cdbb7147" -}}
{{- end }}

{{- define "common.namespace" -}}
{{- .Values.namespace.name | default "carpenter-workshop" -}}
{{- end }}

{{- define "common.ingress.sharedAlbAnnotations" -}}
{{- $groupOrder := .groupOrder | default "10" -}}
{{- $hostname := .hostname -}}
{{- $healthcheckPath := .healthcheckPath | default "/health" -}}
{{- $context := .context -}}
alb.ingress.kubernetes.io/group.name: {{ include "common.sharedAlb.groupName" $context }}
alb.ingress.kubernetes.io/group.order: '{{ $groupOrder }}'
external-dns.alpha.kubernetes.io/hostname: {{ $hostname }}
alb.ingress.kubernetes.io/backend-protocol: {{ $context.Values.commonIngressAnnotations.backendProtocol | default "HTTP" }}
alb.ingress.kubernetes.io/healthcheck-path: {{ $healthcheckPath }}
alb.ingress.kubernetes.io/healthcheck-protocol: {{ $context.Values.commonIngressAnnotations.healthcheck.protocol | default "HTTP" }}
alb.ingress.kubernetes.io/healthcheck-interval-seconds: {{ $context.Values.commonIngressAnnotations.healthcheck.intervalSeconds | default "30" | quote }}
alb.ingress.kubernetes.io/healthcheck-timeout-seconds: {{ $context.Values.commonIngressAnnotations.healthcheck.timeoutSeconds | default "5" | quote }}
alb.ingress.kubernetes.io/healthy-threshold-count: {{ $context.Values.commonIngressAnnotations.healthcheck.healthyThresholdCount | default "2" | quote }}
alb.ingress.kubernetes.io/unhealthy-threshold-count: {{ $context.Values.commonIngressAnnotations.healthcheck.unhealthyThresholdCount | default "2" | quote }}
alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds={{ $context.Values.commonIngressAnnotations.targetGroup.deregistrationDelaySeconds | default 30 }}
{{- end }}
