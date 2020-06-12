variable "vault_version" {
  description = "Vault version"
}

variable "name_prefix" {
  description = "prefix used in resource names"
}

variable "vault_elb_health_check" {
  default     = "/v1/sys/health?activecode=200&standbycode=200&sealedcode=200&uninitcode=200"
  description = "Health check for Vault servers"
}

variable "elb_internal" {
  type        = bool
  default     = true
  description = "make LB internal or external"
}

variable "public_ip" {
  type        = bool
  default     = false
  description = "should ec2 instance have public ip?"
}

variable "instance_type" {
  description = "Instance type for Vault instances"
}

variable "key_name" {
  description = "SSH key name for Vault instances"
}

variable "vault_nodes" {
  description = "number of Vault instances"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "owner" {
  description = "value of owner tag on EC2 instances"
}

variable "vault_cluster_version" {
  description = "Custom Version Tag for Upgrade Migrations"
}

variable "allowed_inbound_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks to permit inbound Vault access from"
  default     = []
}

variable "nat_gateway_subnet_cidr" {
  description = "CIDR block for NAT gateway subnet"
}

variable "lambda_primary_subnet_cidr" {
  description = "CIDR block for primary lambda subnet"
}

variable "lambda_secondary_subnet_cidr" {
  description = "CIDR block for secondary lambda subnet"
}
