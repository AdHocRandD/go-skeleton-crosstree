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


# Delete the VPC in the region, it is not used and should not be used
resource "awsutils_default_vpc_deletion" "default" {
}

# Logging for VPC flow logs


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
  #bridgecrew:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

# TODO
# resource "aws_cloudwatch_log_group" "vpc_flowlogs" {
#   name              = "/aws/vpc/${var.resource_prefix}/flow-logs"
#   retention_in_days = 0
#   kms_key_id        = aws_kms_key.main.arn
# }
# 
# resource "aws_iam_role" "vpc_flowlogs" {
#   name               = "${var.resource_prefix}-vpc-flow-logs"
#   assume_role_policy = data.aws_iam_policy_document.vpc_flowlogs_assume_role.json
# }
# 
# resource "aws_iam_role_policy" "vpc_flowlogs" {
#   name   = "vpc_flowlogs"
#   role   = aws_iam_role.vpc_flowlogs.name
#   policy = data.aws_iam_policy_document.vpc_flowlogs.json
# }
# 
# resource "aws_flow_log" "vpc_flowlogs" {
#   iam_role_arn    = aws_iam_role.vpc_flowlogs.arn
#   log_destination = aws_cloudwatch_log_group.vpc_flowlogs.arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.main.id
# }
