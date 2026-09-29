variable "name" {
  description = "Short name for the VPC (e.g. shared, dev, prod)"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR range"
  type        = string
}

variable "subnet_cidr" {
  description = "Private subnet CIDR (must be inside the VPC CIDR)"
  type        = string
}

variable "az" {
  description = "Availability Zone for the subnet"
  type        = string
}
