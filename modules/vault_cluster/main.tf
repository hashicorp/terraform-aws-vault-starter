data "aws_region" "current" {}

data "aws_vpc" "vault_vpc" {
  id = var.vpc_id
}

data "aws_ami" "ubuntu" {
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

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.vault_vpc.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.name_prefix}-"
}

data "template_file" "install_hashitools_vault" {
  template = file("${path.module}/scripts/install_hashitools_vault.sh.tpl")

  vars = {
    ami           = data.aws_ami.ubuntu.id
    region        = data.aws_region.current.name
    kms_key_id    = aws_kms_key.vault.key_id
    vault_nodes   = var.vault_nodes
    vault_version = var.vault_version
  }
}

resource "aws_lb" "vault" {
  name               = "${random_id.environment_name.hex}-vault-nlb"
  internal           = var.elb_internal
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.default.ids
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = aws_lb.vault.id
  port              = 8200
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

resource "aws_lb_target_group" "vault" {
  name                 = "${random_id.environment_name.hex}-vault-tg"
  target_type          = "instance"
  port                 = 8200
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  deregistration_delay = 15

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.vault_elb_health_check
    interval            = 10
  }
}

resource "aws_autoscaling_group" "vault" {
  name                      = aws_launch_configuration.vault.name
  launch_configuration      = aws_launch_configuration.vault.name
  availability_zones        = data.aws_availability_zones.available.zone_ids
  min_size                  = var.vault_nodes
  max_size                  = var.vault_nodes
  desired_capacity          = var.vault_nodes
  min_elb_capacity          = var.vault_nodes
  wait_for_elb_capacity     = var.vault_nodes
  wait_for_capacity_timeout = "480s"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = data.aws_subnet_ids.default.ids
  target_group_arns         = [aws_lb_target_group.vault.arn]

  tags = [
    {
      key                 = "Name"
      value               = "${random_id.environment_name.hex}-vault-${var.vault_cluster_version}"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster-Version"
      value               = var.vault_cluster_version
      propagate_at_launch = true
    },
    {
      key                 = "owner"
      value               = var.owner
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "vault" {
  name                        = "${random_id.environment_name.hex}-vault-${var.vault_cluster_version}"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  security_groups             = [aws_security_group.vault.id]
  user_data                   = data.template_file.install_hashitools_vault.rendered
  associate_public_ip_address = var.public_ip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  root_block_device {
    volume_type = "io1"
    volume_size = 50
    iops        = "2500"
  }

  lifecycle {
    create_before_destroy = true
  }
}
