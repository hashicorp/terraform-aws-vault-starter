/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

data "aws_region" "current" {}

module "iam" {
  source = "./modules/iam"

  aws_region                  = data.aws_region.current.name
  kms_key_arn                 = module.kms.kms_key_arn
  permissions_boundary        = var.permissions_boundary
  resource_name_prefix        = var.resource_name_prefix
  secrets_manager_arn         = var.secrets_manager_arn
  user_supplied_iam_role_name = var.user_supplied_iam_role_name
}

module "kms" {
  source = "./modules/kms"

  common_tags               = var.common_tags
  kms_key_deletion_window   = var.kms_key_deletion_window
  resource_name_prefix      = var.resource_name_prefix
  user_supplied_kms_key_arn = var.user_supplied_kms_key_arn
}

module "loadbalancer" {
  source = "./modules/load_balancer"

  allowed_inbound_cidrs   = var.allowed_inbound_cidrs_lb
  common_tags             = var.common_tags
  lb_certificate_arn      = var.lb_certificate_arn
  lb_deregistration_delay = var.lb_deregistration_delay
  lb_health_check_path    = var.lb_health_check_path
  lb_subnets              = var.private_subnet_ids
  lb_type                 = var.lb_type
  resource_name_prefix    = var.resource_name_prefix
  ssl_policy              = var.ssl_policy
  vault_sg_id             = module.vm.vault_sg_id
  vpc_id                  = module.networking.vpc_id
}

module "networking" {
  source = "./modules/networking"

  vpc_id = var.vpc_id
}

module "user_data" {
  source = "./modules/user_data"

  aws_region                  = data.aws_region.current.name
  kms_key_arn                 = module.kms.kms_key_arn
  leader_tls_servername       = var.leader_tls_servername
  resource_name_prefix        = var.resource_name_prefix
  secrets_manager_arn         = var.secrets_manager_arn
  user_supplied_userdata_path = var.user_supplied_userdata_path
  vault_version               = var.vault_version
}

locals {
  vault_target_group_arns = concat(
    [module.loadbalancer.vault_target_group_arn],
    var.additional_lb_target_groups,
  )
}

module "vm" {
  source = "./modules/vm"

  allowed_inbound_cidrs     = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh = var.allowed_inbound_cidrs_ssh
  aws_iam_instance_profile  = module.iam.aws_iam_instance_profile
  common_tags               = var.common_tags
  instance_type             = var.instance_type
  key_name                  = var.key_name
  lb_type                   = var.lb_type
  node_count                = var.node_count
  resource_name_prefix      = var.resource_name_prefix
  userdata_script           = module.user_data.vault_userdata_base64_encoded
  user_supplied_ami_id      = var.user_supplied_ami_id
  vault_lb_sg_id            = module.loadbalancer.vault_lb_sg_id
  vault_subnets             = var.private_subnet_ids
  vault_target_group_arns   = local.vault_target_group_arns
  vpc_id                    = module.networking.vpc_id
}
