# Create public subnet
resource "aws_subnet" "pub_sub" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_for_public_subnet
  cidr_block = cidrsubnet(
    var.cidr_block,
    var.pub_subnet_mask - local.vpc_mask,
    count.index,
  )
  availability_zone       = element(var.azs, count.index)

  tags = merge({
    Name = "${var.network_name}-pub-sub-${element(var.azs, count.index)}"
    Tier = "public"
  }, var.tags)
}

# Create private subnet
resource "aws_subnet" "pvt_sub" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block = cidrsubnet(
    var.cidr_block,
    var.pvt_subnet_mask - local.vpc_mask,
    count.index + length(var.azs),
  )
  availability_zone       = element(var.azs, count.index)

  tags = merge({
    Name = "${var.network_name}-pvt-sub-${element(var.azs, count.index)}"
    Tier = "private"
  }, var.tags)
}

# Create data subnet
resource "aws_subnet" "data_sub" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block = cidrsubnet(
    var.cidr_block,
    var.data_subnet_mask - local.vpc_mask,
    count.index + length(var.azs) * 2,
  )
  availability_zone       = element(var.azs, count.index)

  tags = merge({
    Name = "${var.network_name}-data-sub-${element(var.azs, count.index)}"
    Tier = "private"
  }, var.tags)
}