variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "az" {
  description = "Single AZ keeps traffic free (no cross-AZ data charges)"
  type        = string
  default     = "us-east-1a"
}
