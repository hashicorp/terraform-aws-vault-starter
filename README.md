# Vault AWS Module

This is Terraform module for provisioning Vault with [integrated
storage](https://www.vaultproject.io/docs/concepts/integrated-storage) on AWS.
This module defaults to setting up a cluster with 5 Vault nodes (as recommended
by the [Vault with Integrated Storage Reference
Architecture](https://learn.hashicorp.com/vault/operations/raft-reference-architecture#node)).

## About This Module

This module implements the [Vault with Integrated Storage Reference
Architecture](https://learn.hashicorp.com/vault/operations/raft-reference-architecture#node)
on AWS using the Open Source version of Vault.

This module automatically initializes the Vault cluster and places the initial
root token and recovery keys in [AWS Secrets
Manager](https://aws.amazon.com/secrets-manager/).

For practitioners requiring [Consul](https://www.consul.io/) as a storage
backend and/or a wider variety of configurable options out of the box, please
see the [Terraform AWS Vault
Module](https://registry.terraform.io/modules/hashicorp/vault/aws/0.13.7).

## How to Use This Module

Create a Terraform configuration (`main.tf`) that pulls in the module and specifies values
of the required variables:

```hcl
provider "aws" {
  region = "<your AWS region>"
}

module "vault-oss" {
  source                = "hashicorp/vault-starter/aws"
  version               = "<module version>"
  allowed_inbound_cidrs = ["<list of inbound CIDRs>"]
  vpc_id                = "<your VPC id>"
  vault_version         = "<vault version (ex: 1.5.2)>"
  owner                 = "<owner name/tag>"
  name_prefix           = "<name prefix you would like attached to your environment>"
  key_name              = "<your SSH key name>"
  elb_internal          = false
}
```

- `version`: The Vault AWS [module version](https://registry.terraform.io/modules/hashicorp/vault-oss/aws/0.2.1)
  to pull (e.g. `0.2.1`) during the initialization
- `allowed_inbound_cidrs`: Allowed CIDR blocks for SSH and API/UI access
- `vpc_id`: ID of the VPC where cloud resources to be provisioned (see the [Notes](#notes))
- `vault_version`: Desired [Vault version](https://releases.hashicorp.com/vault/)
  to install
- `key_name`: The name of the SSH [key pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#prepare-key-pair)
  to use. This must exist in the specified AWS `region`
- `elb_internal`: To connect to Vault via a load balancer from outside the VPC, set this to `false`

Run `terraform init` and `terraform apply` to provision a Vault cluster.

## License

This code is released under the MPL 2.0 License. Please see
[LICENSE](https://github.com/hashicorp/terraform-aws-vault-oss/blob/master/LICENSE)
for more details.

## Notes

- This modules assumes you are using a default VPC and provides defaults for the
  variables listed below. Please change the values of these variables based on
  your VPC CIDR block. If you are not using a default VPC.

  - `nat_gateway_subnet_cidr`
  - `lambda_primary_subnet_cidr`
  - `lambda_secondary_subnet_cidr`

- This module creates AWS Lambda functions and places them inside the VPC. Due to
  this and some VPC networking changes AWS has recently deployed, it can take up
  45 minutes to successfully delete this environment. See [the following
  documentation](https://www.terraform.io/docs/providers/aws/r/lambda_function.html)
  for more details on this issue.
