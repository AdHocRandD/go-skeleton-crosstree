variable "role_name" {
  type        = string
  description = "The name of the IAM role to create for Github Actions"
}

variable "oidc_provider" {
  type        = string
  description = "The ARN of the OIDC provider for Github Actions"
}

variable "organization" {
  type        = string
  description = "The name of the organization on Github"
}

variable "git_repo_name" {
  type        = string
  description = "The name of the Github repository"
}

variable "ecr_repository_url" {
  type        = string
  description = "The url of the ECR repository"
}
variable "ecr_repository_arn" {
  type        = string
  description = "The arn of the ECR repository"
}

variable "policy_name" {
  type        = string
  description = "The name of the IAM policy for Github Actions"
}
