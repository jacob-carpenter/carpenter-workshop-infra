{{/*
Define a reusable deployment template
Usage: {{ include "common.deployment" . }}
*/}}
{{- define "common.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Values.namespace.name }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.deployment.replicaCount }}
  revisionHistoryLimit: {{ .Values.deployment.revisionHistoryLimit | default 3 }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  strategy:
    type: {{ .Values.deployment.strategy.type | default "RollingUpdate" }}
    {{- if eq (.Values.deployment.strategy.type | default "RollingUpdate") "RollingUpdate" }}
    rollingUpdate:
      maxSurge: {{ .Values.deployment.strategy.rollingUpdate.maxSurge | default 1 }}
      maxUnavailable: {{ .Values.deployment.strategy.rollingUpdate.maxUnavailable | default 0 }}
    {{- end }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- include "common.imagePullSecrets" . | nindent 6 }}
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      {{- with .Values.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - name: {{ .Values.app.name }}
        image: {{ include "common.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy | default "Always" }}
        {{- with .Values.containerSecurityContext }}
        securityContext:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        ports:
        {{- range .Values.service.ports }}
        - name: {{ .name }}
          containerPort: {{ .targetPort }}
          protocol: {{ .protocol | default "TCP" }}
        {{- end }}
        {{- if .Values.healthChecks.liveness.enabled }}
        livenessProbe:
          httpGet:
            {{- toYaml .Values.healthChecks.liveness.httpGet | nindent 12 }}
          initialDelaySeconds: {{ .Values.healthChecks.liveness.initialDelaySeconds }}
          periodSeconds: {{ .Values.healthChecks.liveness.periodSeconds }}
          timeoutSeconds: {{ .Values.healthChecks.liveness.timeoutSeconds }}
          successThreshold: {{ .Values.healthChecks.liveness.successThreshold }}
          failureThreshold: {{ .Values.healthChecks.liveness.failureThreshold }}
        {{- end }}
        {{- if .Values.healthChecks.readiness.enabled }}
        readinessProbe:
          httpGet:
            {{- toYaml .Values.healthChecks.readiness.httpGet | nindent 12 }}
          initialDelaySeconds: {{ .Values.healthChecks.readiness.initialDelaySeconds }}
          periodSeconds: {{ .Values.healthChecks.readiness.periodSeconds }}
          timeoutSeconds: {{ .Values.healthChecks.readiness.timeoutSeconds }}
          successThreshold: {{ .Values.healthChecks.readiness.successThreshold }}
          failureThreshold: {{ .Values.healthChecks.readiness.failureThreshold }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        {{- if .Values.env }}
        env:
        {{- toYaml .Values.env | nindent 8 }}
        {{- end }}
        {{- if .Values.volumes.enabled }}
        volumeMounts:
        {{- toYaml .Values.volumes.volumeMounts | nindent 8 }}
        {{- end }}
      {{- if .Values.volumes.enabled }}
      volumes:
      {{- toYaml .Values.volumes.volumes | nindent 6 }}
      {{- end }}
      {{- with .Values.deployment.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if or .Values.deployment.antiAffinity.enabled .Values.deployment.affinity }}
      affinity:
        {{- if .Values.deployment.affinity }}
        {{- toYaml .Values.deployment.affinity | nindent 8 }}
        {{- end }}
        {{- if .Values.deployment.antiAffinity.enabled }}
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: {{ .Values.deployment.antiAffinity.weight }}
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - {{ .Values.app.name }}
              topologyKey: kubernetes.io/hostname
        {{- end }}
      {{- end }}
{{- end }}
