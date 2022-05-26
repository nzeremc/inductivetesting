provider "aws" {
  region = var.region
}

#================ VPC ===================================
module "network" {
  source           = "./modules/vpc"
  cidr_block       = var.cidr_block
  network_name     = var.network_name
  azs              = var.azs
}

#================ EC2 ===================================
resource "aws_security_group" "app_sg" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.network.vpc_id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
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
    Name = "app-sg"
  }
  depends_on = [
    module.network
  ]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}
# filter - (Optional) One or more name/value pairs to filter off of. There are several valid keys, for a full reference, check out describe-images in the AWS CLI reference.

module "ec2" {
  source                      = "./modules/ec2"
  name                        = var.ec2_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
#   availability_zone           = "ap-south-1a"
  subnet_id                   = module.network.public_subnet_ids[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
#   placement_group             = aws_placement_group.web.id
  associate_public_ip_address = var.associate_public_ip_address

  # only one of these can be enabled at a time
  hibernation = var.hibernation
  # enclave_options_enabled = true

  user_data_base64 = base64encode(<<-EOT
  #!/bin/bash
  echo "hello"
  EOT
  )

#   cpu_core_count       = 2 # default 4
#   cpu_threads_per_core = 1 # default 2

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  enable_volume_tags = var.enable_volume_tags
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
      tags = {
        Name = "root-block"
      }
    },
  ]
  # This is extra disk for the instnace, comment if not required.
  ebs_block_device = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 5
      throughput  = 200
    #   encrypted   = true
    #   kms_key_id  = ""
    }
  ]

  tags = {
    Name        = "app"
    Environment = "dev"
  }
}

#================ RDS ===================================
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow inbound traffic"
  vpc_id      = module.network.vpc_id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
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
    Name = "app-sg"
  }
  depends_on = [
    module.network
  ]
}

module "db" {
  source                = "./modules/rds"
  identifier            = var.db_name
  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine                = var.engine
  engine_version        = var.engine_version
  family                =  var.family# DB parameter group
  major_engine_version  = var. major_engine_version      # DB option group
  instance_class        = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password
  port    =  var.port

  multi_az                              = var.multi_az
  subnet_ids                            = module.network.data_subnet_ids
  vpc_security_group_ids                = [aws_security_group.rds_sg.id]

  maintenance_window                    = var.maintenance_window
  backup_window                         = var.backup_window
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  create_cloudwatch_log_group           = var.create_cloudwatch_log_group

  backup_retention_period               = var.backup_retention_period
  skip_final_snapshot                   = var.skip_final_snapshot
  deletion_protection                   = var.deletion_protection

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  create_monitoring_role                = var.create_monitoring_role
  monitoring_interval                   = var.monitoring_interval

  parameters = [
    {
      name   = "character_set_client"
      value  = "utf8mb4"
    },
    {
      name   = "character_set_server"
      value  = "utf8mb4"
    }
  ]

  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  } 

  tags = {
    Name        = "rds"
    Environment = "dev"
  }
}

######################## ALB #############################
module "alb" {
  source             = "./modules/alb"
  name               = "load-balancer"
  load_balancer_type = "application"
  vpc_id             = module.network.vpc_id
  security_groups    = [module.network.public_web_dmz_sg]
  subnets            = module.network.public_subnet_ids
  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      # action_type        = "forward"
    },
    # {
    #   port        = 81
    #   protocol    = "HTTP"
    #   action_type = "redirect"
    #   redirect = {
    #     port        = "443"
    #     protocol    = "HTTPS"
    #     status_code = "HTTP_301"
    #   }
    # },
    # {
    #   port        = 82
    #   protocol    = "HTTP"
    #   action_type = "fixed-response"
    #   fixed_response = {
    #     content_type = "text/plain"
    #     message_body = "Fixed message"
    #     status_code  = "200"
    #   }
    # },
  ]

  target_groups = [
    {
      name_prefix          = "h1"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 10
      # health_check = {
      #   enabled             = true
      #   interval            = 30
      #   path                = "/health"
      #   port                = "traffic-port"
      #   healthy_threshold   = 3
      #   unhealthy_threshold = 3
      #   timeout             = 6
      #   protocol            = "HTTP"
      #   matcher             = "200-399"
      # }
      protocol_version = "HTTP1"
      targets = {
        my_ec2 = {
          target_id = module.ec2.id
          port      = 80
        },
        my_ec2_again = {
          target_id = module.ec2.id
          port      = 8080
        }
      }
    }
  ]

  tags = {
    Name = "load-balancer"
  }
}