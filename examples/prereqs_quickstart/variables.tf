/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

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

