# ---------- Phase 2: test instances to PROVE the isolation ----------
# 1 tiny EC2 per VPC. Set create_test_instances = false to remove them.

variable "create_test_instances" {
  description = "Create the 3 test EC2 instances + Instance Connect Endpoint"
  type        = bool
  default     = false # flip to true only when testing
}

locals {
  n = var.create_test_instances ? 1 : 0
}

# Latest Amazon Linux 2023 (has EC2 Instance Connect built in)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- Security groups ----------
# ICMP (ping) allowed from ALL internal VPCs (10.0.0.0/8), prod included.
# So if dev -> prod ping fails, it's ROUTING (no peering), not the firewall.

resource "aws_security_group" "eic" {
  count       = local.n
  name        = "dev-eic-endpoint-sg"
  description = "EC2 Instance Connect Endpoint"
  vpc_id      = module.dev.vpc_id

  egress {
    description = "SSH to dev instance only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.dev.cidr_block]
  }
}

resource "aws_security_group" "test" {
  for_each = var.create_test_instances ? {
    shared = module.shared.vpc_id
    dev    = module.dev.vpc_id
    prod   = module.prod.vpc_id
  } : {}

  name        = "${each.key}-test-sg"
  description = "Ping from internal VPCs, SSH only via Instance Connect"
  vpc_id      = each.value

  ingress {
    description = "Ping from internal networks"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  dynamic "ingress" {
    for_each = each.key == "dev" ? [1] : []
    content {
      description     = "SSH only from Instance Connect Endpoint"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [aws_security_group.eic[0].id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${each.key}-test-sg" }
}

# ---------- Free, private access to the dev box (no public IP, no SSH keys) ----------

resource "aws_ec2_instance_connect_endpoint" "dev" {
  count              = local.n
  subnet_id          = module.dev.subnet_id
  security_group_ids = [aws_security_group.eic[0].id]

  tags = { Name = "dev-eic-endpoint" }
}

# ---------- 3 test instances ----------

resource "aws_instance" "test" {
  for_each = var.create_test_instances ? {
    shared = module.shared.subnet_id
    dev    = module.dev.subnet_id
    prod   = module.prod.subnet_id
  } : {}

  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t3.micro" # free-tier eligible
  subnet_id                   = each.value
  vpc_security_group_ids      = [aws_security_group.test[each.key].id]
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required" # IMDSv2 only (security best practice)
  }

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "${each.key}-test" }
}

output "test_private_ips" {
  value = { for k, i in aws_instance.test : k => i.private_ip }
}
