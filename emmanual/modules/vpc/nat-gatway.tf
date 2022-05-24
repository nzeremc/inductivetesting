# Create EIP for private NAT gateway
resource "aws_eip" "nat_eip" {
  count = var.create_pvt_nat || var.create_data_nat ? 1 : 0
  vpc   = true

  tags = merge({
    Name = "${var.network_name}-nat-eip"
  }, var.tags)
}

# Create NAT gateway for private subnet
resource "aws_nat_gateway" "nat_gw" {
  count         = var.create_pvt_nat ? 1 : 0
  subnet_id     = aws_subnet.pub_sub[0].id
  allocation_id = join(", ", aws_eip.nat_eip.*.id)

  tags = merge({
    Name = "${var.network_name}-pvt-nat-gw"
  }, var.tags)
}

# Create EIP for data NAT gateway
resource "aws_eip" "data_nat_eip" {
  # checkov:skip=CKV2_AWS_19: EIP associated to NAT Gateway
  count = var.create_data_nat ? 1 : 0
  vpc   = true

  tags = merge({
    Name = "${var.network_name}-data-nat-eip"
  }, var.tags)
}

# Create NAT gateway for data subnet
resource "aws_nat_gateway" "data_nat_gw" {
  count         = var.create_data_nat ? 1 : 0
  subnet_id     = aws_subnet.pub_sub[1].id
  allocation_id = join(", ", aws_eip.data_nat_eip.*.id)

  tags = merge({
    Name = "${var.network_name}-data-nat-gw"
  }, var.tags)
}