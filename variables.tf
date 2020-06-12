variable "vpc_id" {
  description = "VPC ID"
}

variable "vault_version" {
  description = "Vault version"
}

variable "owner" {
  description = "value of owner tag on EC2 instances"
}

variable "name_prefix" {
  description = "prefix used in resource names"
}

variable "key_name" {
  description = "SSH key name for Vault instances"
}

variable "instance_type" {
  default     = "m5.large"
  description = "Instance type for Vault instances"
}

variable "vault_nodes" {
  default     = "5"
  description = "number of Vault instances"
}

variable "vault_cluster_version" {
  default     = "0.0.1"
  description = "Custom Version Tag for Upgrade Migrations"
}

# The following CIDR blocks are being declared for subnets that
# must be created for the NAT gateway and lambda functions
# they are unlikely ton conflict with default subnets in
# default VPCs, but you should change these if you are using a custom
# VPC or have modified your default subnets configuration

variable "nat_gateway_subnet_cidr" {
  description = "CIDR block for NAT gateway subnet"
  default     = "172.31.160.0/20"
}

variable "lambda_primary_subnet_cidr" {
  description = "CIDR block for primary lambda subnet"
  default     = "172.31.128.0/20"
}

variable "lambda_secondary_subnet_cidr" {
  description = "CIDR block for secondary lambda subnet"
  default     = "172.31.144.0/20"
}
