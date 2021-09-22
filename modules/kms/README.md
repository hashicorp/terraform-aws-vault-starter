# AWS KMS Module

## Required variables

* `kms_key_deletion_window` - Duration in days after which the key is deleted after destruction of the resource (must be between 7 and 30 days)
* `resource_name_prefix` - Resource name prefix used for tagging and naming AWS resources

## Example usage

```hcl
module "kms" {
  source = "./modules/kms"

  kms_key_deletion_window   = var.kms_key_deletion_window
  resource_name_prefix      = var.resource_name_prefix
}
```
