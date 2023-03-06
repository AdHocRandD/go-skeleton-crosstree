variable "cluster_name" {
  type        = string
  description = "The name of the ECS Cluster"
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the ECS repository."
}
