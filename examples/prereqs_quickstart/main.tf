/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./aws-vpc/"

  azs                  = var.azs
  common_tags          = var.tags
  resource_name_prefix = var.resource_name_prefix
}

module "secrets" {
  source = "./secrets/"

  resource_name_prefix = var.resource_name_prefix
}

