output "vault_subnet_ids" {
  value = data.aws_subnets.vault.ids
}

output "vpc_id" {
  value = data.aws_vpc.selected.id
}
