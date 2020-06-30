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

For practitioners requiring [Consul](https://www.consul.io/) as a storage
backend and/or a wider variety of configurable options out of the box, please
see the [Terraform AWS Vault
Module](https://registry.terraform.io/modules/hashicorp/vault/aws/0.13.7).

## How to Use This Module

- Create a Terraform configuration that pulls in the module and specifies values
  of the requires variables:

```hcl
provider "aws" {
  region = "<your AWS region>"
}

module "vault_cluster" {
  source = "https://github.com/hashicorp/terraform-aws-vault-oss.git"

  vpc_id        = "<your VPC id>"
  vault_version = "<vault version (ex: 1.4.2)>"
  owner         = "<owner name/tag>"
  name_prefix   = "<name prefix you would like attached to your environment>"
  key_name      = "<your SSH key name>"
}
```

- If you want to use a certain release of the module, specify the `ref` tag in
  your source option as shown below:

```hcl
provider "aws" {
  region = "<your AWS region>"
}

module "vault_cluster" {
  source = "https://github.com/hashicorp/terraform-aws-vault-oss.git?ref=v0.1.0"

  vpc_id        = "<your VPC id>"
  vault_version = "<vault version (ex: 1.4.2)>"
  owner         = "<owner name/tag>"
  name_prefix   = "<name prefix you would like attached to your environment>"
  key_name      = "<your SSH key name>"
}
```

- Run `terraform init` and `terraform apply`

## Note

This module creates AWS Lambda functions and places them inside the VPC. Due to
this and some VPC networking changes AWS has recently deployed, it can take up
45 minutes to successfully delete this environment. See [the following
documentation](https://www.terraform.io/docs/providers/aws/r/lambda_function.html)
for more details on this issue.
