# Restrict default security group to deny all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

# Create private security group
resource "aws_security_group" "pvt_sg" {
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-private-sg"
  description = "Security group allowing communication within the VPC for ingress"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.network_name}-private-sg"
  }, var.tags)
}

# Create protected security group for all communications strictly within the VPC
resource "aws_security_group" "protected_sg" {
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-protected-sg"
  description = "Security group allowing all communications strictly within the VPC"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }

  tags = merge({
    Name = "${var.network_name}-protected-sg"
  }, var.tags)
}

# Create security group for public facing web servers or load balancer
resource "aws_security_group" "pub_sg" {
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-pub-web-sg"
  description = "Security group allowing 80 and 443 from outer world"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.network_name}-pub-web-sg"
  }, var.tags)
}

# Create security group for internal web/app servers
resource "aws_security_group" "pvt_web_sg" {
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-pvt-web-sg"
  description = "Security group allowing 80 and 443 internally for app servers"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = aws_security_group.pub_sg.*.id
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = aws_security_group.pub_sg.*.id
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = aws_security_group.pub_sg.*.id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.network_name}-pvt-web-sg"
  }, var.tags)
}