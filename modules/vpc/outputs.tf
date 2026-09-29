output "vpc_id" {
  value = aws_vpc.this.id
}

output "cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "subnet_id" {
  value = aws_subnet.private.id
}

output "route_table_id" {
  value = aws_route_table.private.id
}
