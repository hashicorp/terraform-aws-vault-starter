locals {
  launch_template_tags = merge(
    {
      Name                                = "${var.resource_name_prefix}-vault-server"
      "${var.resource_name_prefix}-vault" = "server"
    },
    var.common_tags
  )
}

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

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "6.5.1"

  name = "${var.resource_name_prefix}-vault"

  min_size         = var.node_count
  max_size         = var.node_count
  desired_capacity = var.node_count

  vpc_zone_identifier = var.vault_subnets
  security_groups = [
    aws_security_group.vault.id,
  ]

  # TODO var wait for capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  health_check_type         = var.asg_health_check_type
  health_check_grace_period = var.asg_health_check_grace_period

  # Required for KMS volume encryption.
  service_linked_role_arn = var.autoscaling_service_linked_role_arn

  # Launch template
  launch_template_name        = "${var.resource_name_prefix}-vault"
  launch_template_description = "Launch template for the ${var.resource_name_prefix} vault cluster."
  launch_template_version     = "$Latest"
  update_default_version      = true
  ebs_optimized               = false
  image_id                    = var.user_supplied_ami_id != null ? var.user_supplied_ami_id : data.aws_ami.ubuntu[0].id
  instance_type               = var.instance_type
  key_name                    = var.key_name != null ? var.key_name : null
  enable_monitoring           = false

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/sda1"
      ebs = {
        delete_on_termination = true
        volume_size           = 100
        volume_type           = "gp3"
        iops                  = 3000
        throughput            = 150
        encrypted             = true
        kms_key_id            = var.backend_kms_key_arn
      }
    },
  ]

  iam_instance_profile_arn = var.aws_iam_instance_profile

  target_group_arns = var.vault_target_group_arns

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = local.launch_template_tags
    },
    {
      resource_type = "volume"
      tags          = local.launch_template_tags
    }
  ]

  metadata_options = {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = var.userdata_script
}
