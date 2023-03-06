variable "app_name" {
  type        = string
  description = "The name of the ECS service and task definition"
}

variable "cluster_id" {
  type        = string
  description = "The ID of the ECS cluster to deploy the service to"
}

variable "cluster_name" {
  type        = string
  description = "The ID of the ECS cluster to deploy the service to"
}

variable "ecr_repository_url" {
  type        = string
  description = "The URL of the ECR repository containing the Docker image"
}

variable "container_port" {
  type        = number
  description = "The port that the container listens on"
  default     = 80
}

variable "desired_count" {
  type        = number
  description = "The number of tasks to run"
  default     = 1
}

variable "task_memory" {
  type        = string
  description = "The amount of memory to allocate for the task"
  default     = "512"
}

variable "task_cpu" {
  type        = string
  description = "The amount of CPU to allocate for the task"
  default     = "256"
}

variable "environment" {
  type        = map(string)
  description = "A map of environment variables to set in the container"
  default     = {}
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to launch the task in"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy the service to"
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether to assign a public IP address to the task"
  default     = true
}

variable "task_container_image" {
  type        = string
  description = "The container to be used for ECS task"
}

variable "task_container_environment" {
  type = map(string)
  default = {
    TEST_VARIABLE = "TEST_VALUE"
  }
}

variable "name_prefix" {
  type = string
}
variable "task_container_port" {
  type = string
}
variable "task_container_assign_public_ip" {
  type = bool
}

variable "health_check" {
  type = map(string)
  default = {
    port = "traffic-port"
    path = "/"
  }
}

variable "tags" {
  type = map(string)
  default = {
    environment = "dev"
    terraform   = "True"
  }
}
