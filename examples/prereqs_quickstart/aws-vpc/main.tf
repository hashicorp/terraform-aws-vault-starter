/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  version                = "3.0.0"
  name                   = "${var.resource_name_prefix}-vault"
  cidr                   = var.vpc_cidr
  azs                    = var.azs
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs

  tags = var.common_tags
}

