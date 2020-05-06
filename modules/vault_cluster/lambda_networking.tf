resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.nat_gateway.id
}

resource "aws_subnet" "nat_gateway" {
  vpc_id     = data.aws_vpc.vault_vpc.id
  cidr_block = var.nat_gateway_subnet_cidr
}

resource "aws_subnet" "lambda_primary" {
  vpc_id     = data.aws_vpc.vault_vpc.id
  cidr_block = var.lambda_primary_subnet_cidr
}

resource "aws_subnet" "lambda_secondary" {
  vpc_id     = data.aws_vpc.vault_vpc.id
  cidr_block = var.lambda_secondary_subnet_cidr
}

resource "aws_route_table" "lambda" {
  vpc_id = data.aws_vpc.vault_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
}

resource "aws_route_table_association" "lambda_primary" {
  subnet_id      = aws_subnet.lambda_primary.id
  route_table_id = aws_route_table.lambda.id
}

resource "aws_route_table_association" "lambda_secondary" {
  subnet_id      = aws_subnet.lambda_secondary.id
  route_table_id = aws_route_table.lambda.id
}

resource "aws_iam_policy" "lambda_manage_network_interfaces" {
  name        = "${random_id.environment_name.hex}-vault-lambda-net"
  path        = "/"
  description = "IAM policy for managing network interfaces"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

