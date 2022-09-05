variable "allowed_inbound_cidrs_lb" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks to permit inbound traffic from to load balancer."
  default     = null
}

variable "allowed_inbound_cidrs_ssh" {
  description = "(Optional) List of CIDR blocks to permit for SSH to Vault nodes."
  type        = list(string)
  default     = null
}

variable "additional_lb_target_groups" {
  description = "(Optional) List of load balancer target groups to associate with the Vault cluster. These target groups are _in addition_ to the LB target group this module provisions by default."
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "(Optional) Map of common tags for all taggable AWS resources."
  type        = map(string)
  default     = {}
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "m5.xlarge"
}

variable "key_name" {
  description = "(Optional) key pair to use for SSH access to instance."
  type        = string
  default     = null
}

variable "kms_key_deletion_window" {
  description = "Duration in days after which the key is deleted after destruction of the resource (must be between 7 and 30 days)."
  type        = number
  default     = 7
}

variable "kms_key_administrators" {
  # TODO: We can reduce the code used by this variable when 1.3.0 is released. This will be achieved using optional object attributes.
  description = <<DOC
    An object map containing KMS key administratoy policy attributes.

    Used by the KMS policy.

    Inputes:
    - type: The principal type.
    - identifiers: The principal identifiers.
  DOC
  type = object({
    type         = string
    identitfiers = list(string)
  })
  default = null
}

variable "custom_kms_backend_policy" {
  description = "(Optional): A custom KMS policy to attach to the backend KMS keys."
  type        = string
  default     = null
}

variable "custom_kms_seal_unseal_policy" {
  description = "(Optional): A custom KMS policy to attach to the backend KMS keys."
  type        = string
  default     = null
}

variable "leader_tls_servername" {
  description = "One of the shared DNS SAN used to create the certs use for mTLS."
  type        = string
}

variable "lb_certificate_arn" {
  description = "ARN of TLS certificate imported into ACM for use with LB listener."
  type        = string
}

variable "lb_deregistration_delay" {
  description = "Amount time, in seconds, for Vault LB target group to wait before changing the state of a deregistering target from draining to unused."
  type        = string
  default     = 300
}

variable "lb_health_check_path" {
  description = "The endpoint to check for Vault's health status."
  type        = string
  default     = "/v1/sys/health?activecode=200&standbycode=200&sealedcode=200&uninitcode=200"
}

variable "lb_type" {
  description = "The type of load balancer to provision; network or application."
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.lb_type)
    error_message = "The variable lb_type must be one of: application, network."
  }
}

variable "node_count" {
  description = "Number of Vault nodes to deploy in ASG."
  type        = number
  default     = 5
}

variable "permissions_boundary" {
  description = "(Optional) IAM Managed Policy to serve as permissions boundary for created IAM Roles."
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Subnet IDs to deploy Vault into."
  type        = list(string)
}

variable "resource_name_prefix" {
  description = "Resource name prefix used for tagging and naming AWS resources."
  type        = string
}

variable "tls_cert_secrets_manager_arn" {
  description = "Secrets manager ARN where TLS cert info is stored."
  type        = string
}

variable "vault_ent_license_secret_manager_arn" {
  description = "(Optional) Secret manager ARN where a vault enterprise license is stored."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL policy to use on LB listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "user_supplied_ami_id" {
  description = "(Optional) User-provided AMI ID to use with Vault instances. If you provide this value, please ensure it will work with the default userdata script (assumes latest version of Ubuntu LTS). Otherwise, please provide your own userdata script using the user_supplied_userdata_path variable."
  type        = string
  default     = null
}

variable "user_supplied_iam_role_name" {
  description = "(Optional) User-provided IAM role name. This will be used for the instance profile provided to the AWS launch configuration. The minimum permissions must match the defaults generated by the IAM submodule for cloud auto-join and auto-unseal."
  type        = string
  default     = null
}

variable "user_supplied_userdata_path" {
  type        = string
  description = "(Optional) File path to custom userdata script being supplied by the user."
  default     = null
}

variable "vault_version" {
  description = "Vault version."
  type        = string
  default     = "1.11.0"
}

variable "vpc_id" {
  description = "VPC ID where Vault will be deployed."
  type        = string
}

variable "asg_health_check_grace_period" {
  description = "Time after instance comes into service before checking health."
  type        = string
  default     = null
}

variable "asg_health_check_type" {
  description = "'EC2' or 'ELB'. Controls how health checking is done. Set this to ELB once you have verified the service starts up properly."
  type        = string
  default     = "EC2"
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out."
  type        = string
  default     = null
}

variable "internal_zone_id" {
  description = "This is the zone if that the autoscale DNS service will use to update the private R53 A records."
  type        = string
}
