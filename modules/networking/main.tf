data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "vault" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = var.private_subnet_tags
}
