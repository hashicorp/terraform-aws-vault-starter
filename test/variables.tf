/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

variable "common_tags" { type = map(string) }
variable "resource_name_prefix" { type = string }

variable "azs" {
  description = "Availability zones to use in AWS region"
  type        = list(string)
}

variable "permissions_boundary" {
  description = "IAM Managed Policy to serve as permissions boundary for created IAM Roles"
  type        = string
  default     = null
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Region in which to launch resources"
}
