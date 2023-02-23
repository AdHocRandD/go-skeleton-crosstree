# vars.tf
variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to all resources in this module"
}

variable "region" {
  description = "the AWS region to build the project in"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block to use when creating the VPC"
  type        = string
  default     = "10.0.2.0/23"
}

variable "vpc_public_subnet_cidr_blocks" {
  description = "List of public subnet cidrs to use with the VPC, each subnet gets a unique availability zone. Amount of subnets must be under amount of availability zones available in a region."
  type        = list(string)
  default = [
    "10.0.2.0/26",
    "10.0.2.64/26",
    "10.0.2.128/26"
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

variable "vpc_public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
}

variable "vpc_private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 3
}

# Define the prefix length for the public and private subnets
variable "vpc_public_subnet_prefix" {
  description = "Prefix length for the VPC public subnets"
  type        = number
  default     = 24
}

variable "vpc_private_subnet_prefix" {
  description = "Prefix length for the VPC private subnets"
  type        = number
  default     = 24
}