output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (ALB tier)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of private app-tier subnet IDs (EC2/ASG)"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "List of private data-tier subnet IDs (RDS)"
  value       = aws_subnet.private_data[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.this[*].id
}
