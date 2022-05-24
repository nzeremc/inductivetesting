# Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "${var.network_name}-bastion-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance_type
  key_name      = var.bastion_key_name
  subnet_id     = aws_subnet.pub_sub.0.id
  security_groups = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "${var.network_name}-bastion-host"
  }
}