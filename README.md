# Carpenter Workshop Infrastructure

Shared infrastructure repository for carpenter workshop projects, providing core AWS infrastructure and Kubernetes baseline configurations.

## Overview

This repository contains:
- **Terraform modules** for provisioning AWS infrastructure (VPC, compute, security, ACM, Route53, ECR)
- **Kubernetes baseline** helm chart with core cluster services (ingress, load balancer controller, external-dns, cert-manager)
- **Common app library** helm chart for shared application patterns
- **GitHub Actions workflows** for automated deployment

## Repository Structure

```
.
├── terraform/                  # Infrastructure as Code
│   ├── modules/               # Reusable Terraform modules
│   └── environments/          # Environment-specific configurations
├── kubernetes/
│   ├── cluster-baseline/      # Core cluster services helm chart
│   └── apps/                  # Application-specific helm charts
├── charts/                    # Helm charts published to GitHub Pages
│   └── common-app-library/    # Shared application helm library
└── .github/workflows/         # CI/CD automation
```

## Infrastructure Components

### Terraform Modules
- **VPC**: Multi-AZ networking with public subnets
- **Compute**: K3s cluster on EC2 (control plane + worker nodes)
- **Security**: Security groups and IAM roles
- **ACM**: SSL/TLS certificate management
- **Route53**: DNS management
- **ECR**: Container registry

### Kubernetes Baseline
Core cluster services deployed via helm:
- AWS Load Balancer Controller
- external-dns for Route53 integration
- cert-manager for certificate management
- ECR credential helper for private registry access

### Common App Library
Reusable helm chart library providing:
- Standard deployment patterns
- Ingress configurations
- Service account management
- Security context templates

Published to GitHub Pages at: `https://jacob-carpenter.github.io/carpenter-workshop-infra`

## Deployment

Deployments are automated via GitHub Actions workflows that deploy on push to `main` or via manual workflow dispatch.

### Workflows
- **deploy-environment.yml**: Orchestrates infrastructure and cluster baseline deployment
- **deploy-terraform.yml**: Reusable workflow for Terraform deployments
- **deploy-helm.yml**: Reusable workflow for Helm deployments
- **publish-helm-chart.yml**: Publishes common-app-library to GitHub Pages

### Environment Configuration

Infrastructure and applications use environment-specific values files:
- `values-base.yaml`: Shared configuration
- `values-{env}.yaml`: Environment-specific overrides (prod/staging/dev)

Dynamic values (certificate ARNs, IPs) are injected from AWS SSM Parameter Store during deployment.

## TODO

- [ ] Add PR workflows for linting/validation/security scanning
- [ ] Add architecture diagrams

### Longer Term

- [ ] Static dependency/security scanners
- [ ] Live security scan agent for vulnerability testing