# Create public route table
resource "aws_route_table" "pub_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge({
    Name = "${var.network_name}-pub-rtb"
  }, var.tags)
}

resource "aws_route_table_association" "pub_rtb_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.pub_sub[count.index].id
  route_table_id = aws_route_table.pub_rtb.id
}

# Create private route table
resource "aws_route_table" "pvt_rtb" {
  count  = var.create_pvt_nat == false ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-pvt-rtb"
  }, var.tags)
}

resource "aws_route_table" "pvt_nat_rtb" {
  count  = var.create_pvt_nat ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = join(", ", aws_nat_gateway.nat_gw.*.id)
  }

  tags = merge({
    Name = "${var.network_name}-pvt-rtb"
  }, var.tags)
}

resource "aws_route_table_association" "pvt_rtb_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.pvt_sub[count.index].id
  route_table_id = var.create_pvt_nat ? join(", ", aws_route_table.pvt_nat_rtb.*.id) : join(", ", aws_route_table.pvt_rtb.*.id)
}

# Create data route table
resource "aws_route_table" "data_rtb" {
  count  = var.create_data_nat == false ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-data-rtb"
  }, var.tags)
}

resource "aws_route_table" "data_nat_rtb" {
  count  = var.create_data_nat ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = join(", ", aws_nat_gateway.data_nat_gw.*.id)
  }

  tags = merge({
    Name = "${var.network_name}-data-rtb"
  }, var.tags)
}

resource "aws_route_table_association" "data_rtb_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.data_sub[count.index].id
  route_table_id = var.create_data_nat ? join(", ", aws_route_table.data_nat_rtb.*.id) : join(", ", aws_route_table.data_rtb.*.id)
}