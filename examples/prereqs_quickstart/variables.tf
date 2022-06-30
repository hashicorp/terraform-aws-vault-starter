variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "availability zones to use in AWS region"
  type        = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags for VPC resources"
  default     = {}
}

variable "resource_name_prefix" {
  description = "Prefix for resource names in VPC infrastructure"
}

