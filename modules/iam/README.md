# AWS IAM Module

## Required variables

* `aws_region` - Specific AWS region being used.
* `kms_key_arn` - KMS Key ARN used for Vault auto-unseal permissions.
* `resource_name_prefix` - Resource name prefix used for tagging and naming AWS resources.
* `secret_manager_arns` - A list of secret manager arns that will be referenced in the IAM role.

## Example usage

```hcl
module "iam" {
  source = "./modules/iam"

  aws_region                   = data.aws_region.current.name
  kms_key_arn                  = var.kms_key_arn
  resource_name_prefix         = var.resource_name_prefix
  secret_manager_arns          = compact([var.tls_cert_secrets_manager_arn, var.vault_ent_license_secret_manager_arn])
}
```
