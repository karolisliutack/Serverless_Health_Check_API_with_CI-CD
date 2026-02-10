output "vpc_id" {
  description = "VPC ID"
  value       = var.enabled ? aws_vpc.main[0].id : null
}

output "subnet_ids" {
  description = "Private subnet IDs"
  value       = var.enabled ? aws_subnet.private[*].id : []
}

output "security_group_id" {
  description = "Lambda security group ID"
  value       = var.enabled ? aws_security_group.lambda[0].id : null
}
