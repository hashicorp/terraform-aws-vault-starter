data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  identifier = "vault-enterprise-${var.resource_name_prefix}"
}

/**
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *    Instance IAM ROLE / Policy / Profile
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

data "aws_iam_policy_document" "instance_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name                 = format("%s-instance", local.identifier)
  permissions_boundary = var.permissions_boundary
  assume_role_policy   = data.aws_iam_policy_document.instance_assume_role.json

  tags = merge(
    { Name = format("%s-instance", local.identifier) },
    var.common_tags,
  )
}

resource "aws_iam_instance_profile" "instance" {
  name = local.identifier
  role = aws_iam_role.instance.name
}

# Required if the volumes on the launch template are encrypted using the project KMS key.
resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = local.identifier
}

module "iam_policies" {
  source = "./modules/iam_policies"

  resource_name_prefix = var.resource_name_prefix
  kms_key_arn_backend  = module.kms.backend_kms_key_arn
  kms_key_arn_seal     = module.kms.vault_seal_unseal_kms_key_arn
  iam_role_arn         = aws_iam_role.instance.id
  secret_manager_arns  = compact([var.tls_cert_secrets_manager_arn, var.vault_ent_license_secret_manager_arn])
}

module "kms" {
  source = "./modules/kms"

  resource_name_prefix                = var.resource_name_prefix
  kms_key_administrators              = var.kms_key_administrators
  kms_key_deletion_window             = var.kms_key_deletion_window
  common_tags                         = var.common_tags
  account_id                          = data.aws_caller_identity.current.account_id
  custom_kms_backend_policy           = var.custom_kms_backend_policy
  custom_kms_seal_unseal_policy       = var.custom_kms_seal_unseal_policy
  autoscaling_service_linked_role_arn = aws_iam_service_linked_role.autoscaling.arn
  instance_role_arn                   = aws_iam_role.instance.arn
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
  vpc_id                  = var.vpc_id
}

module "user_data" {
  source = "./modules/user_data"

  aws_region                           = data.aws_region.current.name
  kms_seal_unseal_key_arn              = module.kms.vault_seal_unseal_kms_key_arn
  leader_tls_servername                = var.leader_tls_servername
  resource_name_prefix                 = var.resource_name_prefix
  tls_cert_secrets_manager_arn         = var.tls_cert_secrets_manager_arn
  vault_ent_license_secret_manager_arn = var.vault_ent_license_secret_manager_arn
  user_supplied_userdata_path          = var.user_supplied_userdata_path
  vault_version                        = var.vault_version
}

locals {
  vault_target_group_arns = concat(
    [module.loadbalancer.vault_target_group_arn],
    var.additional_lb_target_groups,
  )
}

module "vm" {
  source = "./modules/vm"

  allowed_inbound_cidrs               = var.allowed_inbound_cidrs_lb
  allowed_inbound_cidrs_ssh           = var.allowed_inbound_cidrs_ssh
  aws_iam_instance_profile            = aws_iam_instance_profile.instance.arn
  common_tags                         = var.common_tags
  instance_type                       = var.instance_type
  key_name                            = var.key_name
  lb_type                             = var.lb_type
  node_count                          = var.node_count
  resource_name_prefix                = var.resource_name_prefix
  userdata_script                     = module.user_data.vault_userdata_base64_encoded
  user_supplied_ami_id                = var.user_supplied_ami_id
  vault_lb_sg_id                      = module.loadbalancer.vault_lb_sg_id
  vault_subnets                       = var.private_subnet_ids
  vault_target_group_arns             = local.vault_target_group_arns
  vpc_id                              = var.vpc_id
  asg_health_check_type               = var.asg_health_check_type
  asg_health_check_grace_period       = var.asg_health_check_grace_period
  autoscaling_service_linked_role_arn = aws_iam_service_linked_role.autoscaling.arn
  wait_for_capacity_timeout           = var.wait_for_capacity_timeout
  backend_kms_key_arn                 = module.kms.backend_kms_key_arn
  leader_tls_servername               = var.leader_tls_servername
  internal_zone_id                    = var.internal_zone_id
}
