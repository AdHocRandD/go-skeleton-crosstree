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
  description = "The repo namne"
  type        = string
  default     = "{{ .RepoName }}"
}
