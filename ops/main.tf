# * what's a sane tagging system? What tags can/ought be generally provided?
# * is it best practice to pin a version for all dependencies?

provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "{{ .TerraformBucket }}"
    key            = "terraform.tfstate"
    region         = "{{ .Region }}"
    dynamodb_table = "{{ .TerraformBucket }}-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0, < 4.0.0"
    }
  }
}

# XXX: do we want a repository policy?
# https://github.com/Vlaaaaaaad/blog-scaling-containers-in-aws/blob/5fcf9645d9ce27ed2ac529b0dec020460d1832f3/ecr/ecr-repos.tf#L24
resource "aws_ecr_repository" "main" {
  name = var.ecr_repository_name
  tags = {}

  image_scanning_configuration {
    scan_on_push = true
  }
}

#######################
# github ECR OICD setup

# working from https://blog.tedivm.com/guides/2021/10/github-actions-push-to-aws-ecr-without-credentials-oidc/
# and https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
#
# to find this thumbprint, I:
# - went to https://token.actions.githubusercontent.com/.well-known/openid-configuration
# - got the jwks url of: https://token.actions.githubusercontent.com/.well-known/jwks
# - ran: openssl s_client -servername token.actions.githubusercontent.com -showcerts -connect token.actions.githubusercontent.com:443
# - saved the last cert (MIIE6jCCA...E4f97Q=) as /tmp/cert.cert
# - ran: openssl x509 -in /tmp/cert.cert -fingerprint -noout
# - which yields a thumbprint of: 6938FD4D98BAB03FAADB97B34396831E3780AEA1
#
# I see this fingerprint in other repos in github, so maybe it's right?
#
# Here's a script for the first 3 steps:
#
# token_host=$(curl -s https://token.actions.githubusercontent.com/.well-known/openid-configuration | jq -r .jwks_uri | awk -F[/:] '{print $4}') && \
#   openssl s_client -servername "$token_host" -showcerts -connect "$token_host":443
#
# but then pulling the last cert out of that stream (and that command seems to
# hang for me) is more painful than I'm willing to do ATM
resource "aws_iam_openid_connect_provider" "github-{{ .ProjectID }}" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# XXX: `terraform plan` always wants to re-create this action
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github-{{ .ProjectID }}.arn]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.organization}/${var.repo_name}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-${var.organization}-${var.repo_name}"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [aws_ecr_repository.main.arn]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "github-actions-${var.repo_name}"
  description = "Grant Github Actions the ability to push to ${var.repo_name} from ${var.organization}/${var.repo_name}"
  policy      = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# End Github OICD
####################

data "aws_vpc" "main" {
  id = aws_vpc.main.id
}

# https://github.com/telia-oss/terraform-aws-ecs-fargate/blob/c3ba251c8ab6bb18957b9a34ac7f5ed174170f78/examples/basic/main.tf
module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "3.0.0"

  name_prefix = var.name_prefix
  type        = "application"
  internal    = false
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = [for k in aws_subnet.public : k.id]

  tags = {
    environment          = "dev"
    terraform            = "True"
    Provisioned-by       = "crosstree"
    crosstree-id         = var.project_id
    crosstree-repository = var.repo_name
  }

  depends_on = [
    aws_route_table_association.public
  ]
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = module.fargate_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = module.fargate.target_group_arn
    type             = "forward"
  }
}

resource "aws_security_group_rule" "task_ingress_8000" {
  security_group_id        = module.fargate.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8000
  to_port                  = 8000
  source_security_group_id = module.fargate_alb.security_group_id
}

resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = module.fargate_alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"

  # do we want spot instances? What are the benefits/disadvantages?
  # capacity_providers = [
  #   "FARGATE_SPOT",
  # ]

  # default_capacity_provider_strategy {
  #   capacity_provider = "FARGATE_SPOT"
  #   weight            = 1
  #   base              = 3500
  # }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

module "fargate" {
  source  = "telia-oss/ecs-fargate/aws"
  version = "6.0.0"

  cluster_id         = aws_ecs_cluster.cluster.id
  vpc_id             = data.aws_vpc.main.id
  private_subnet_ids = [for k in aws_subnet.private : k.id]
  lb_arn             = coalesce(module.fargate_alb.arn, "")

  name_prefix          = var.name_prefix
  task_container_image = "{{ .AmazonAccountID }}.dkr.ecr.{{ .Region }}.amazonaws.com/{{ .RepoName }}:main"

  # public ip is needed for default vpc, default is false
  task_container_assign_public_ip = true

  # port, default protocol is HTTP
  task_container_port = 8000

  task_container_port_mappings = [
    {
      containerPort = 9000
      hostPort      = 9000
      protocol      = "tcp"
    }
  ]

  task_container_environment = {
    TEST_VARIABLE = "TEST_VALUE"
  }

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  depends_on = [
    module.fargate_alb,
  ]
}
