variable "ecr_repository_name" {
  description = "Name to use for the ECR repository"
  type        = string
  default     = "{{ .ECRName }}"
}

variable "name_prefix" {
  type    = string
  default = "{{ .ProjectName }}"
}

variable "organization" {
  description = "The organization your github repo is in"
  type        = string
  default     = "{{ .Organization }}"
}

variable "repo_name" {
  description = "The repo name"
  type        = string
  default     = "{{ .RepoName }}"
}

variable "project_id" {
  description = "the crosstree project id"
  type        = string
  default     = "{{ .ProjectID }}"
}

variable "region" {
  description = "the AWS region to build the project in"
  type        = string
  default     = "{{ .Region }}"
}
