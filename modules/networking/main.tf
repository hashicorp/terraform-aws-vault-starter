data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet_ids" "vault" {
  vpc_id = data.aws_vpc.selected.id
  tags   = var.private_subnet_tags
}
