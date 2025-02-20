output "public_instance_ids" {
  value = { for k, v in aws_instance.public_hosts : k => v.id }
}

output "private_instance_ids" {
  value = { for k, v in aws_instance.private_hosts : k => v.id }
}

output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public_sg.id
}

output "private_security_group_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.private_sg.id
}