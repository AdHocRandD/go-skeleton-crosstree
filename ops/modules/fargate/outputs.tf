output "service_arn" {
  value = module.fargate.service_arn
}

output "endpoint" {
  value = module.fargate_alb.dns_name
}