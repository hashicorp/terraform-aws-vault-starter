variable "private_subnet_tags" {
  type        = map(string)
  description = "Tags which specify the subnets to deploy Vault into"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Vault will be deployed"
}
