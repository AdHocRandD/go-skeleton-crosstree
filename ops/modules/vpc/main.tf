# VPC tf file
# Contains files needed to build out the VPC network
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_availability_zones" "current" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  tags                 = var.tags
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public" {
  for_each          = toset(var.vpc_public_subnet_cidr_blocks)
  availability_zone = data.aws_availability_zones.current.names[index(var.vpc_public_subnet_cidr_blocks, each.value)]
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  tags              = var.tags
}

resource "aws_subnet" "private" {
  for_each          = toset(var.vpc_private_subnet_cidr_blocks)
  availability_zone = data.aws_availability_zones.current.names[index(var.vpc_private_subnet_cidr_blocks, each.value)]
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  tags              = var.tags
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

# Create a internet facing routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
  tags = var.tags
}

# Associate the route table with the public subnets

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

data "aws_iam_policy_document" "vpc_flowlogs_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# Allow the VPC to create the necessary flow log groups
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "vpc_flowlogs" {
  statement {
    effect = "Allow"
    actions = [
                "logs:CreateLogDelivery",
                "logs:GetLogDelivery",
                "logs:UpdateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:ListLogDeliveries",
                "logs:PutLogEvents",
                "logs:PutResourcePolicy",
                "logs:DescribeResourcePolicies",
                "logs:DescribeLogGroups"

    ]
    resources = ["*"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_vpc.main.main_route_table_id
  ]

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecs_agent" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "ecs_telemetry" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}


resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.reporting-sg-ecr.id]
  subnet_ids          = [for k in aws_subnet.private : k.id]

  tags = var.tags
}

# sg to allow ecs to pull ecr
resource "aws_security_group" "reporting-sg-ecr" {
  description = "security group allowing access to ecr for md5sum tagging service"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

resource "aws_security_group_rule" "ecr-ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.reporting-sg-ecr.id
  cidr_blocks       = ["10.0.0.1/32"]  # allow access from specific IP address
}

resource "aws_security_group_rule" "ecr-egress" {
  from_port         = 443
  protocol          = "TCP"
  to_port           = 443
  security_group_id = aws_security_group.reporting-sg-ecr.id
  self              = true
  description       = "allow egress to ecr"
  type              = "egress"
}
resource "aws_security_group_rule" "ecr-ecs-ingress" {
  from_port         = 443
  protocol          = "TCP"
  to_port           = 443
  security_group_id = aws_security_group.reporting-sg-ecr.id
  self              = true
  description       = "allow ingress from ecr"
  type              = "ingress"
}
resource "aws_security_group_rule" "ecr-vpc-ingress" {
  from_port         = 443
  protocol          = "TCP"
  to_port           = 443
  security_group_id = aws_security_group.reporting-sg-ecr.id
  cidr_blocks       = [var.vpc_cidr_block]
  description       = "allow ingress from vpc cidr block"
  type              = "ingress"
}
resource "aws_security_group_rule" "ecr-vpc-egress" {
  from_port         = 443
  protocol          = "TCP"
  to_port           = 443
  security_group_id = aws_security_group.reporting-sg-ecr.id
  cidr_blocks       = [var.vpc_cidr_block]
  description       = "allow egress to vpc cidr block"
  type              = "egress"
}
