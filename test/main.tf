/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

terraform {
  cloud {
    organization = "hc-tfc-dev"

    workspaces {
      tags = [
        "integrationtest",
      ]
    }
  }

  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.7"
    }

    testingtoolsaws = {
      source  = "app.terraform.io/hc-tfc-dev/testingtoolsaws"
      version = "~> 0.3"
    }
  }
}

provider "aws" {
  region = var.region
}
provider "testingtoolsaws" {
  region = var.region
}

module "quickstart" {
  source = "../examples/prereqs_quickstart"

  aws_region           = var.region
  azs                  = var.azs
  resource_name_prefix = var.resource_name_prefix
  tags                 = var.common_tags
}

module "vault" {
  source = "../"

  common_tags           = var.common_tags
  leader_tls_servername = module.quickstart.leader_tls_servername
  lb_certificate_arn    = module.quickstart.lb_certificate_arn
  permissions_boundary  = var.permissions_boundary
  private_subnet_ids    = module.quickstart.private_subnet_ids
  resource_name_prefix  = var.resource_name_prefix
  secrets_manager_arn   = module.quickstart.secrets_manager_arn
  vpc_id                = module.quickstart.vpc_id
}


data "aws_instances" "servers" {
  instance_state_names = [
    "running",
  ]

  instance_tags = {
    "aws:autoscaling:groupName" = module.vault.asg_name
    "aws:ec2launchtemplate:id"  = module.vault.launch_template_id
  }
}

resource "testingtoolsaws_ssm_runcommand" "wait_for_server_bootup" {
  document_name              = "AWS-RunShellScript"
  instance_ids               = sort(data.aws_instances.servers.ids)
  wait_for_managed_instances = true

  parameters = {
    commands = "date && while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 5; done && date"
  }
}

resource "testingtoolsaws_ssm_runcommand" "bootstrap_vault" {
  document_name = "AWS-RunShellScript"

  instance_ids = [
    data.aws_instances.servers.ids[0],
  ]

  parameters = {
    commands = "VAULT_ADDR=\"https://127.0.0.1:8200\" VAULT_CACERT=\"/opt/vault/tls/vault-ca.pem\" VAULT_CLIENT_CERT=\"/opt/vault/tls/vault-cert.pem\" VAULT_CLIENT_KEY=\"/opt/vault/tls/vault-key.pem\" vault operator init"
  }

  depends_on = [
    testingtoolsaws_ssm_runcommand.wait_for_server_bootup,
  ]
}

locals {
  bootstrap_token = sensitive(regex("Initial Root Token: ([.a-zA-Z0-9]*)", testingtoolsaws_ssm_runcommand.bootstrap_vault.outputs[0].StandardOutputContent)[0])
}
