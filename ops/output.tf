#
# create an ECR repository
# see ops/push_docker.sh for interacting with it
#
output "ecr_repository_name" {
  value = var.ecr_repository_name
}

resource "aws_ssm_parameter" "ecr_repository_name" {
  name  = "/terraform/outputs/ecr_repository_name"
  type  = "String"
  tier  = "Standard"
  value = var.ecr_repository_name
}
