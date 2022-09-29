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

variable "vpc_public_subnet_cidr_blocks" {
  description = "List of public subnet cidrs to use with the VPC, each subnet gets a unique availability zone. Amount of subnets must be under amount of availability zones available in a region."
  type        = list(string)
  default = [
    "10.0.5.0/26",
    "10.0.5.64/26",
    "10.0.5.128/26"
  ]
}

variable "vpc_private_subnet_cidr_blocks" {
  description = "List of private subnet cidrs to use with the VPC, each subnet gets a unique availability zone. Amount of subnets must be under amount of availability zones available in a region."
  type        = list(string)
  default = [
    "10.0.3.0/26",
    "10.0.3.64/26",
    "10.0.3.128/26"
  ]
}

variable "tags" {
  description = "A map of resource tags to append to all resources"
  type        = map(string)
  default = {
    environment  = "development"
    organization = "{{ .Organization }}"
    project      = "{{ .ProjectName }}"
    repository   = "{{ .RepoName }}"
    project_id   = "{{ .ProjectID }}"
  }
}
