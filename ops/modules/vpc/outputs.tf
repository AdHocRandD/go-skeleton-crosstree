# outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.public.id
}

output "s3_vpc_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "logs_vpc_endpoint_id" {
  value = aws_vpc_endpoint.logs.id
}

output "reporting_security_group_id" {
  value = aws_security_group.reporting-sg-ecr.id
}
