{{/*
Define a reusable service template
Usage: {{ include "common.service" . }}
*/}}
{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}
  namespace: {{ .Values.namespace.name }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  ports:
  {{- range .Values.service.ports }}
  - name: {{ .name }}
    port: {{ .port }}
    targetPort: {{ .targetPort }}
    protocol: {{ .protocol | default "TCP" }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
{{- end }}
