# Common App Library

A Helm library chart providing reusable templates and helpers for carpenter-workshop applications, including support for the shared Application Load Balancer (ALB) pattern.

## Overview

This library chart standardizes:
- **Shared ALB Configuration**: Multiple apps share a single ALB to reduce costs
- **Common Labels**: Consistent Kubernetes labels across all resources
- **Naming Helpers**: Standard resource naming conventions
- **Ingress Annotations**: Automated generation of ALB ingress annotations

## Shared ALB Architecture

Instead of creating a dedicated ALB for each application, multiple applications share a single ALB with host-based routing:

```
┌──────────────────────────────────────────────────┐
│     Application Load Balancer (Shared)          │
│     Group: carpenter-workshop-shared             │
├──────────────────────────────────────────────────┤
│  Host: importmap.carpenterworkshop.net → App 1  │
│  Host: carpenterworkshop.net → App 2            │
│  Host: api.carpenterworkshop.net → App 3        │
└──────────────────────────────────────────────────┘
```

**Benefits**:
- Cost savings: ~$16/month per ALB avoided
- Centralized SSL/TLS management
- Simplified DNS configuration

## Usage

### 1. Add Dependency

In your application's `Chart.yaml`:

```yaml
dependencies:
  - name: common-app-library
    version: 1.0.0
    repository: "file://../../../../../carpenter-workshop-infra/kubernetes/apps/common-app-library"
```

### 2. Configure Values

In your `values.yaml`, add the shared ALB configuration:

```yaml
# Common App Library Configuration
sharedAlb:
  groupName: carpenter-workshop-shared
  certificateArn: arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT_ID

commonIngressAnnotations:
  backendProtocol: HTTP
  healthcheck:
    protocol: HTTP
    intervalSeconds: "30"
    timeoutSeconds: "5"
    healthyThresholdCount: "2"
    unhealthyThresholdCount: "2"
  targetGroup:
    deregistrationDelaySeconds: 30

commonLabels:
  project: carpenter-workshop
  managed-by: helm

namespace:
  name: carpenter-workshop

# Ingress configuration
ingress:
  enabled: true
  className: alb
  groupOrder: "10"  # Routing priority (lower = higher)
  hostname: myapp.carpenterworkshop.net
  healthcheckPath: /health
  extraAnnotations: {}  # Add custom annotations here
```

### 3. Update Ingress Template

In your `templates/ingress.yaml`:

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.app.name }}
  namespace: {{ include "common.namespace" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    app: {{ .Values.app.name }}
  annotations:
    {{- $sharedAlbConfig := dict "groupOrder" (.Values.ingress.groupOrder | default "10") "hostname" (.Values.ingress.hostname | required ".Values.ingress.hostname is required") "healthcheckPath" (.Values.ingress.healthcheckPath | default "/health") "context" . -}}
    {{- include "common.ingress.sharedAlbAnnotations" $sharedAlbConfig | nindent 4 }}
    {{- with .Values.ingress.extraAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  ingressClassName: alb
  rules:
    - host: {{ .Values.ingress.hostname }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.app.name }}
                port:
                  number: {{ .Values.service.port }}
{{- end }}
```

### 4. Build Dependencies

```bash
cd your-app-chart
helm dependency update
```

### 5. Test Template

```bash
helm template my-app . --namespace carpenter-workshop
```

## Available Helpers

### `common.labels`
Returns standard Kubernetes labels for all resources.

```yaml
labels:
  {{- include "common.labels" . | nindent 4 }}
```

### `common.namespace`
Returns the configured namespace name.

```yaml
namespace: {{ include "common.namespace" . }}
```

### `common.sharedAlb.groupName`
Returns the shared ALB group name.

```yaml
alb.ingress.kubernetes.io/group.name: {{ include "common.sharedAlb.groupName" . }}
```

### `common.sharedAlb.certificateArn`
Returns the ACM certificate ARN.

```yaml
alb.ingress.kubernetes.io/certificate-arn: {{ include "common.sharedAlb.certificateArn" . }}
```

### `common.ingress.sharedAlbAnnotations`
Generates all shared ALB ingress annotations.

**Parameters**:
- `groupOrder` (required): Routing priority (lower = higher)
- `hostname` (required): DNS hostname
- `healthcheckPath` (optional): Health check path, defaults to `/health`
- `context` (required): Template context (`.`)

```yaml
{{- $config := dict "groupOrder" "10" "hostname" "app.example.com" "healthcheckPath" "/health" "context" . -}}
{{- include "common.ingress.sharedAlbAnnotations" $config | nindent 4 }}
```

**Generated Annotations**:
```yaml
alb.ingress.kubernetes.io/group.name: carpenter-workshop-shared
alb.ingress.kubernetes.io/group.order: '10'
external-dns.alpha.kubernetes.io/hostname: app.example.com
alb.ingress.kubernetes.io/backend-protocol: HTTP
alb.ingress.kubernetes.io/healthcheck-path: /health
alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
alb.ingress.kubernetes.io/healthcheck-interval-seconds: "30"
alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
alb.ingress.kubernetes.io/healthy-threshold-count: "2"
alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
alb.ingress.kubernetes.io/target-group-attributes: deregistration_delay.timeout_seconds=30
```

### Other Helpers

- `common.name`: Chart name
- `common.fullname`: Full resource name
- `common.chart`: Chart name and version
- `common.selectorLabels`: Selector labels for pods/services
- `common.serviceAccountName`: Service account name
- `common.imagePullSecrets`: Image pull secrets
- `common.image`: Full image name with registry/repository/tag

## Group Order Guidelines

The `group.order` annotation determines routing rule priority (lower = higher priority):

| Range | Purpose | Examples |
|-------|---------|----------|
| 1-9 | Baseline/Infrastructure | Shared ALB baseline (1) |
| 10-99 | Application Services | Import Map (10), Main App (20), API (30) |
| 100+ | Catch-all/Default | Error pages, fallback routes |

## Examples

### Basic Application

```yaml
# values.yaml
ingress:
  groupOrder: "20"
  hostname: myapp.carpenterworkshop.net
  healthcheckPath: /api/health
```

### Application with Custom Annotations

```yaml
# values.yaml
ingress:
  groupOrder: "30"
  hostname: api.carpenterworkshop.net
  healthcheckPath: /health
  extraAnnotations:
    alb.ingress.kubernetes.io/success-codes: "200,201,204"
    alb.ingress.kubernetes.io/target-group-attributes: stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=86400
```

## Prerequisites

The shared ALB baseline must be deployed first via the cluster-baseline chart:

```bash
cd carpenter-workshop-infra/kubernetes/cluster-baseline
helm upgrade --install cluster-baseline . --namespace cluster-baseline
```

This creates the shared ALB that applications join.

## Troubleshooting

### Error: template not found

**Cause**: Dependency not installed
**Solution**: Run `helm dependency update` in your app chart directory

### Multiple ALBs Created

**Cause**: Group name mismatch
**Solution**: Verify all ingresses use `groupName: carpenter-workshop-shared`

### Annotations Not Applied

**Cause**: Helper not called correctly
**Solution**: Ensure you're passing `context` parameter: `dict ... "context" .`

## See Also

- [Cluster Baseline Chart](../../cluster-baseline/README.md)
- [AWS Load Balancer Controller Docs](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Ingress Groups](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/ingress_class/#ingress-group)
