variable "allowed_inbound_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks to permit inbound traffic from to load balancer"
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  type        = list(string)
  description = "List of CIDR blocks to give SSH access to Vault nodes"
  default     = null
}

variable "aws_iam_instance_profile" {
  type        = string
  description = "IAM instance profile name to use for Vault instances"
}

variable "common_tags" {
  type        = map(string)
  description = "(Optional) Map of common tags for all taggable AWS resources."
  default     = {}
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "m5.xlarge"
}

variable "key_name" {
  type        = string
  description = "key pair to use for SSH access to instance"
  default     = null
}

variable "lb_type" {
  description = "The type of load balancer to provision: network or application."
  type        = string
}

variable "node_count" {
  type        = number
  description = "Number of Vault nodes to deploy in ASG"
  default     = 5
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
}

variable "userdata_script" {
  type        = string
  description = "Userdata script for EC2 instance"
}

variable "user_supplied_ami_id" {
  type        = string
  description = "AMI ID to use with Vault instances"
  default     = null
}

variable "vault_lb_sg_id" {
  type        = string
  description = "Security group ID of Vault load balancer"
}

variable "vault_subnets" {
  type        = list(string)
  description = "Private subnets where Vault will be deployed"
}

variable "vault_target_group_arns" {
  type        = list(string)
  description = "Target group ARN(s) to register Vault nodes with"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Vault will be deployed"
}

variable "asg_health_check_grace_period" {
  description = "Time after instance comes into service before checking health."
  type        = string
  default     = null
}

variable "asg_health_check_type" {
  description = "'EC2' or 'ELB'. Controls how health checking is done. Set this to ELB once you have verified the service starts up properly"
  type        = string
  default     = null
}

variable "autoscaling_service_linked_role_arn" {
  description = "The role arn used by the autoscaling group. Used in the module managed KMS policy."
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out."
  type        = string
  default     = null
  nullable    = true
}

variable "backend_kms_key_arn" {
  description = "KMS Key ARN used for other encryption / decryption mechanisms."
  type        = string
}
