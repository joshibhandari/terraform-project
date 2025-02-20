output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# output "vpc_id" {
#   description = "The ID of the VPC"
#   value       = concat(module.vpc.vpc_id.*.id, [""])[0]
# }

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value = module.vpc.public_subnet_ids
}


output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "private_nat_gateway_route_ids" {
  description = "List of IDs of the private nat gateway route."
  value       = module.vpc.private_nat_gateway_route_ids
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = var.azs
}

output "name" {
  description = "The name of the VPC specified as argument to this module"
  value       = var.name
}

variable "external_nat_ips" {
  description = "List of EIPs to be used for `nat_public_ips` output (used in combination with reuse_nat_ips and external_nat_ip_ids)"
  type        = list(string)
  default     = []
}


output "public_instance_ids" {
  description = "list of public instance ids"
  value = module.ec2.public_instance_ids
}

output "private_instance_ids" {
  description = "list of private instance ids"
  value = module.ec2.private_instance_ids
}