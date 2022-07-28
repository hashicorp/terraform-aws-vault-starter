/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

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
