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
}
locals {
  name_prefix     = var.name_prefix
  app_name        = "${local.name_prefix}-${local.tags.environment}"
  container_image = "{{ .AmazonAccountID }}.dkr.ecr.{{ .Region }}.amazonaws.com/{{ .RepoName }}:main"
  organization    = var.organization
  git_repo_name   = var.repo_name
  git_role_name   = "github-actions-${local.organization}-${local.git_repo_name}"
  oidc_provider   = var.oidc_provider
  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

# resource "null_resource" "create_iam_and_fargate" {
#   count = can(module.ecr) && can(module.ecs) ? 1 : 0
#   provisioner "local-exec" {
#     command = "echo Create IAM and Fargate resources"
#   }
# }

module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  region         = var.region
  tags           = local.tags
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = local.name_prefix
  tags            = local.tags
  region          = var.region

}
module "ecs" {
  source       = "./modules/ecs"
  cluster_name = "${local.name_prefix}-cluster"
  tags         = local.tags
  depends_on   = [module.vpc]
  }

module "iam" {
  source             = "./modules/iam"
  role_name          = "github-actions-${var.organization}-${var.repo_name}"
  oidc_provider    = local.oidc_provider
  organization       = local.organization
  git_repo_name      = local.git_repo_name
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn
  policy_name        = "github-actions-${local.git_repo_name}"
  depends_on   = [module.ecr, module.ecs, module.vpc]
  # depends_on         = [null_resource.create_iam_and_fargate]

}

module "fargate" {
  source                          = "./modules/fargate"
  name_prefix                     = var.name_prefix
  app_name                        = local.app_name
  ecr_repository_url              = module.ecr.repository_url
  cluster_id                      = module.ecs.cluster_id
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnet_ids
  task_container_image            = local.container_image
  task_container_assign_public_ip = true
  task_container_port             = 8000
  task_container_environment = {
    TEST_VARIABLE = "TEST_VALUE"
  }
  health_check = {
    port = "traffic-port"
    path = "/"
  }
  tags       = local.tags
  depends_on = [module.ecs, module.iam, module.vpc, module.ecr]
}
