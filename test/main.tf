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
      version = "~> 0.2"
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

# TODO: this sleep is much more imprecise than it should be
# Would be better to have a resource that waited until the ASG instances
# appeared as managed instances in SSM instead of adding a 2 minute
# buffer on top of a needed ~6 minute delay before they appear
resource "time_sleep" "wait_for_servers_to_appear_in_ssm" {
  create_duration = "8m"

  depends_on = [
    module.vault,
  ]
}

data "aws_instances" "servers" {
  instance_state_names = [
    "running",
  ]

  instance_tags = {
    "aws:ec2launchtemplate:id" = module.vault.launch_template_id
  }

  depends_on = [
    time_sleep.wait_for_servers_to_appear_in_ssm,
  ]
}

resource "testingtoolsaws_ssm_runcommand" "wait_for_server_bootup" {
  count = 5

  document_name = "AWS-RunShellScript"

  instance_ids = [
    data.aws_instances.servers.ids[count.index],
  ]

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
