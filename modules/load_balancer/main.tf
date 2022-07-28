/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

resource "aws_security_group" "vault_lb" {
  count       = var.lb_type == "application" ? 1 : 0
  description = "Security group for the application load balancer"
  name        = "${var.resource_name_prefix}-vault-lb-sg"
  vpc_id      = var.vpc_id

  tags = merge(
    { Name = "${var.resource_name_prefix}-vault-lb-sg" },
    var.common_tags,
  )
}

resource "aws_security_group_rule" "vault_lb_inbound" {
  count             = var.lb_type == "application" && var.allowed_inbound_cidrs != null ? 1 : 0
  description       = "Allow specified CIDRs access to load balancer on port 8200"
  security_group_id = aws_security_group.vault_lb[0].id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "vault_lb_outbound" {
  count                    = var.lb_type == "application" ? 1 : 0
  description              = "Allow outbound traffic from load balancer to Vault nodes on port 8200"
  security_group_id        = aws_security_group.vault_lb[0].id
  type                     = "egress"
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = var.vault_sg_id
}

locals {
  lb_security_groups = var.lb_type == "network" ? null : [aws_security_group.vault_lb[0].id]
  lb_protocol        = var.lb_type == "network" ? "TCP" : "HTTPS"
}

resource "aws_lb" "vault_lb" {
  name                       = "${var.resource_name_prefix}-vault-lb"
  internal                   = true
  load_balancer_type         = var.lb_type
  subnets                    = var.lb_subnets
  security_groups            = local.lb_security_groups
  drop_invalid_header_fields = var.lb_type == "application" ? true : null

  tags = merge(
    { Name = "${var.resource_name_prefix}-vault-lb" },
    var.common_tags,
  )
}

resource "aws_lb_target_group" "vault" {
  name                 = "${var.resource_name_prefix}-vault-tg"
  deregistration_delay = var.lb_deregistration_delay
  target_type          = "instance"
  port                 = 8200
  protocol             = local.lb_protocol
  vpc_id               = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTPS"
    port                = "traffic-port"
    path                = var.lb_health_check_path
    interval            = 30
  }

  tags = merge(
    { Name = "${var.resource_name_prefix}-vault-tg" },
    var.common_tags,
  )
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = aws_lb.vault_lb.id
  port              = 8200
  protocol          = local.lb_protocol
  ssl_policy        = local.lb_protocol == "HTTPS" ? var.ssl_policy : null
  certificate_arn   = local.lb_protocol == "HTTPS" ? var.lb_certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}
