output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = aws_security_group.vault.id
}

output "autoscaling_group_arn" {
  description = "The ARN for this AutoScaling Group."
  value       = module.autoscaling.autoscaling_group_arn
}

output "autoscaling_group_availability_zones" {
  description = "The availability zones of the autoscale group."
  value       = module.autoscaling.autoscaling_group_availability_zones
}

output "autoscaling_group_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group."
  value       = module.autoscaling.autoscaling_group_desired_capacity
}

output "autoscaling_group_launch_template" {
  description = "Launch template attributes used by the autoscaling group."
  value = {
    arn             = module.autoscaling.launch_template_arn
    id              = module.autoscaling.launch_template_id
    name            = module.autoscaling.launch_template_name
    default_version = module.autoscaling.launch_template_default_version
    latest_version  = module.autoscaling.launch_template_latest_version
  }
}
