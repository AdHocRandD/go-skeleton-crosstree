variable "repository_name" {
  type        = string
  description = "The name of the ECR repository to create."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the ECR repository."
}

variable "region" {
  description = "the AWS region to build the project in"
  type        = string
}