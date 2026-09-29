# ---------- 3 VPCs (non-overlapping CIDRs, required for peering) ----------

module "shared" {
  source      = "./modules/vpc"
  name        = "shared"
  cidr_block  = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
  az          = var.az
}

module "dev" {
  source      = "./modules/vpc"
  name        = "dev"
  cidr_block  = "10.1.0.0/16"
  subnet_cidr = "10.1.1.0/24"
  az          = var.az
}

module "prod" {
  source      = "./modules/vpc"
  name        = "prod"
  cidr_block  = "10.2.0.0/16"
  subnet_cidr = "10.2.1.0/24"
  az          = var.az
}

# ---------- Peering: hub (shared) <-> each spoke ----------
# No dev <-> prod link. Peering is NOT transitive, so dev can't reach prod.

resource "aws_vpc_peering_connection" "shared_dev" {
  vpc_id      = module.shared.vpc_id
  peer_vpc_id = module.dev.vpc_id
  auto_accept = true # same account + region

  tags = { Name = "pcx-shared-dev" }
}

resource "aws_vpc_peering_connection" "shared_prod" {
  vpc_id      = module.shared.vpc_id
  peer_vpc_id = module.prod.vpc_id
  auto_accept = true

  tags = { Name = "pcx-shared-prod" }
}

# ---------- Routes (both directions for each peering) ----------

resource "aws_route" "shared_to_dev" {
  route_table_id            = module.shared.route_table_id
  destination_cidr_block    = module.dev.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_dev.id
}

resource "aws_route" "dev_to_shared" {
  route_table_id            = module.dev.route_table_id
  destination_cidr_block    = module.shared.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_dev.id
}

resource "aws_route" "shared_to_prod" {
  route_table_id            = module.shared.route_table_id
  destination_cidr_block    = module.prod.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_prod.id
}

resource "aws_route" "prod_to_shared" {
  route_table_id            = module.prod.route_table_id
  destination_cidr_block    = module.shared.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.shared_prod.id
}
