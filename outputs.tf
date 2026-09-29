output "vpc_ids" {
  value = {
    shared = module.shared.vpc_id
    dev    = module.dev.vpc_id
    prod   = module.prod.vpc_id
  }
}

output "peering_ids" {
  value = {
    shared_dev  = aws_vpc_peering_connection.shared_dev.id
    shared_prod = aws_vpc_peering_connection.shared_prod.id
  }
}
