output "vault_seal_unseal_kms_key_arn" {
  value = module.kms.vault_seal_unseal_kms_key_arn
}

output "backend_kms_key_arn" {
  value = module.kms.backend_kms_key_arn
}

output "vault_lb_dns_name" {
  description = "DNS name of Vault load balancer"
  value       = module.loadbalancer.vault_lb_dns_name
}

output "vault_lb_zone_id" {
  description = "Zone ID of Vault load balancer"
  value       = module.loadbalancer.vault_lb_zone_id
}

output "vault_lb_arn" {
  description = "ARN of Vault load balancer"
  value       = module.loadbalancer.vault_lb_arn
}

output "vault_target_group_arn" {
  description = "Target group ARN to register Vault nodes with"
  value       = module.loadbalancer.vault_target_group_arn
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = module.vm.vault_sg_id
}

output "ec2_instance_iam_role_attributes" {
  description = "The attributes of the IAM role used by the terraform enterprise instances."
  value = {
    arn          = aws_iam_role.instance.arn
    name         = aws_iam_role.instance.name
    profile_arn  = aws_iam_instance_profile.instance.arn
    profile_id   = aws_iam_instance_profile.instance.id
    profile_name = aws_iam_instance_profile.instance.name
  }
}

output "autoscaling_group_arn" {
  description = "The ARN for this AutoScaling Group."
  value       = module.vm.autoscaling_group_arn
}

output "autoscaling_group_availability_zones" {
  description = "The availability zones of the autoscale group."
  value       = module.vm.autoscaling_group_availability_zones
}

output "autoscaling_group_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group."
  value       = module.vm.autoscaling_group_desired_capacity
}

output "autoscaling_group_launch_template" {
  description = "Launch template attributes used by the autoscaling group."
  value       = module.vm.autoscaling_group_launch_template
}
