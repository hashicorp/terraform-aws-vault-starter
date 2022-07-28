/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

data "aws_ami" "ubuntu" {
  count       = var.user_supplied_ami_id != null ? 0 : 1
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "vault" {
  name   = "${var.resource_name_prefix}-vault"
  vpc_id = var.vpc_id

  tags = merge(
    { Name = "${var.resource_name_prefix}-vault-sg" },
    var.common_tags,
  )
}

resource "aws_security_group_rule" "vault_internal_api" {
  description       = "Allow Vault nodes to reach other on port 8200 for API"
  security_group_id = aws_security_group.vault.id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "vault_internal_raft" {
  description       = "Allow Vault nodes to communicate on port 8201 for replication traffic, request forwarding, and Raft gossip"
  security_group_id = aws_security_group.vault.id
  type              = "ingress"
  from_port         = 8201
  to_port           = 8201
  protocol          = "tcp"
  self              = true
}

# The following data source gets used if the user has
# specified a network load balancer.
# This will lock down the EC2 instance security group to
# just the subnets that the load balancer spans
# (which are the private subnets the Vault instances use)

data "aws_subnet" "subnet" {
  count = length(var.vault_subnets)
  id    = var.vault_subnets[count.index]
}

locals {
  subnet_cidr_blocks = [for s in data.aws_subnet.subnet : s.cidr_block]
}

resource "aws_security_group_rule" "vault_network_lb_inbound" {
  count             = var.lb_type == "network" ? 1 : 0
  description       = "Allow load balancer to reach Vault nodes on port 8200"
  security_group_id = aws_security_group.vault.id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  cidr_blocks       = local.subnet_cidr_blocks
}

resource "aws_security_group_rule" "vault_application_lb_inbound" {
  count                    = var.lb_type == "application" ? 1 : 0
  description              = "Allow load balancer to reach Vault nodes on port 8200"
  security_group_id        = aws_security_group.vault.id
  type                     = "ingress"
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = var.vault_lb_sg_id
}

resource "aws_security_group_rule" "vault_network_lb_ingress" {
  count             = var.lb_type == "network" && var.allowed_inbound_cidrs != null ? 1 : 0
  description       = "Allow specified CIDRs access to load balancer and nodes on port 8200"
  security_group_id = aws_security_group.vault.id
  type              = "ingress"
  from_port         = 8200
  to_port           = 8200
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs
}

resource "aws_security_group_rule" "vault_ssh_inbound" {
  count             = var.allowed_inbound_cidrs_ssh != null ? 1 : 0
  description       = "Allow specified CIDRs SSH access to Vault nodes"
  security_group_id = aws_security_group.vault.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_inbound_cidrs_ssh
}

resource "aws_security_group_rule" "vault_outbound" {
  description       = "Allow Vault nodes to send outbound traffic"
  security_group_id = aws_security_group.vault.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "vault" {
  name          = "${var.resource_name_prefix}-vault"
  image_id      = var.user_supplied_ami_id != null ? var.user_supplied_ami_id : data.aws_ami.ubuntu[0].id
  instance_type = var.instance_type
  key_name      = var.key_name != null ? var.key_name : null
  user_data     = var.userdata_script
  vpc_security_group_ids = [
    aws_security_group.vault.id,
  ]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = 100
      throughput            = 150
      iops                  = 3000
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = var.aws_iam_instance_profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_autoscaling_group" "vault" {
  name                = "${var.resource_name_prefix}-vault"
  min_size            = var.node_count
  max_size            = var.node_count
  desired_capacity    = var.node_count
  vpc_zone_identifier = var.vault_subnets
  target_group_arns   = var.vault_target_group_arns

  launch_template {
    id      = aws_launch_template.vault.id
    version = "$Latest"
  }

  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${var.resource_name_prefix}-vault-server"
        propagate_at_launch = true
      }
    ],
    [
      {
        key                 = "${var.resource_name_prefix}-vault"
        value               = "server"
        propagate_at_launch = true
      }
    ],
    [
      for k, v in var.common_tags : {
        key                 = k
        value               = v
        propagate_at_launch = true
      }
    ]
  )
}
