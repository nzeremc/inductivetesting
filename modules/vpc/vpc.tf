# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block                       = var.cidr_block
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  instance_tenancy                 = var.instance_tenancy
  assign_generated_ipv6_cidr_block = var.assign_ipv6_cidr_block

  tags = merge({
    Name = var.network_name
  }, var.tags)
}

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
}

locals {
  vpc_mask = element(split("/", var.cidr_block), 1)
}