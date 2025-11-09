# Security Groups Module

# Data source to get VPC CIDR
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Security Group for Control Plane (base resource without cross-references)
resource "aws_security_group" "control_plane" {
  name_prefix = "${var.project_name}-${var.environment}-control-plane-"
  description = "Security group for K8s control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-control-plane-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Worker Nodes (base resource without cross-references)
resource "aws_security_group" "worker_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-workers-"
  description = "Security group for K8s worker nodes"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-workers-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Control Plane Ingress Rules
resource "aws_security_group_rule" "control_plane_ssh" {
  type              = "ingress"
  description       = "SSH from allowed CIDRs"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.control_plane.id
}

resource "aws_security_group_rule" "control_plane_api_vpc" {
  type              = "ingress"
  description       = "K3s API Server from VPC"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.control_plane.id
}

resource "aws_security_group_rule" "control_plane_api_external" {
  type              = "ingress"
  description       = "K3s API Server from allowed external IPs"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_api_cidrs
  security_group_id = aws_security_group.control_plane.id
}

resource "aws_security_group_rule" "control_plane_from_workers" {
  type                     = "ingress"
  description              = "All traffic from workers"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.worker_nodes.id
  security_group_id        = aws_security_group.control_plane.id
}

resource "aws_security_group_rule" "control_plane_self" {
  type              = "ingress"
  description       = "All traffic within control plane"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.control_plane.id
}

# Worker Nodes Ingress Rules
resource "aws_security_group_rule" "worker_ssh" {
  type              = "ingress"
  description       = "SSH from allowed CIDRs"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.worker_nodes.id
}

resource "aws_security_group_rule" "worker_http_from_alb" {
  type                     = "ingress"
  description              = "HTTP from ALB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.worker_nodes.id
}

resource "aws_security_group_rule" "worker_https_from_alb" {
  type                     = "ingress"
  description              = "HTTPS from ALB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.worker_nodes.id
}

resource "aws_security_group_rule" "worker_nodeport_from_alb" {
  type                     = "ingress"
  description              = "NodePort from ALB"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.worker_nodes.id
}

resource "aws_security_group_rule" "worker_from_control_plane" {
  type                     = "ingress"
  description              = "All traffic from control plane"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.worker_nodes.id
}

resource "aws_security_group_rule" "worker_self" {
  type              = "ingress"
  description       = "All traffic within workers"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.worker_nodes.id
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
