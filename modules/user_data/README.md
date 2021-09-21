# AWS User Data Module

## Required variables

* `aws_region` - AWS region where Vault is being deployed
* `kms_key_arn` - KMS Key ARN used for Vault auto-unseal
* `leader_tls_servername` - One of the shared DNS SAN used to create the certs use for mTLS
* `resource_name_prefix` - Resource name prefix used for tagging and naming AWS resources
* `secrets_manager_arn` - Secrets manager ARN where TLS cert info is stored
* `vault_version` - Vault version

## Example usage

```hcl
module "user_data" {
  source = "./modules/user_data"

  aws_region               = data.aws_region.current.name
  kms_key_arn              = var.kms_key_arn
  leader_tls_servername    = var.leader_tls_servername
  resource_name_prefix     = var.resource_name_prefix
  secrets_manager_arn      = var.secrets_manager_arn
  vault_version            = var.vault_version
}
```
