variable "region" {
  default = "us-east-1"
}

#=============== VPC =====================

variable "cidr_block" {
  default = "10.18.0.0/16"
}

variable "network_name" {
  default = "pvt-network"
}

variable "azs" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"] 
}

#================= EC2 =====================
variable "ec2_name" {
  default = "app"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "demo"
}

variable "associate_public_ip_address" {
  default = true
}

variable "hibernation" {
  default = true
}

variable "capacity_reservation_preference" {
  default = "open"
}

variable "enable_volume_tags" {
  default = false
}


#================= RDS =====================
variable "engine" {
  default = "mysql"
}

variable "engine_version" {
  default = "8.0.27"
}

variable "family" {
  default = "mysql8.0"
}

variable "major_engine_version" {
  default = "8.0"
}

variable "instance_class" {
  default =  "db.t4g.large"
}

variable "allocated_storage" {
  default = 20
}

variable "max_allocated_storage" {
  default = 100
}

variable "db_name" {
  default = "rdsdb"
}

variable "username" {
  default = "rdsuser"
}

variable "password" {
  default = "admin123"
}

variable "port" {
  default = 3306
}

variable "multi_az" {
  default = true
}

variable "maintenance_window" {
  default = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  default = "03:00-06:00"
}

variable "enabled_cloudwatch_logs_exports" {
  default = ["general"]
}

variable "create_cloudwatch_log_group" {
  default = true
}

variable "backup_retention_period" {
  default = 0
}

variable "skip_final_snapshot" {
  default = true
}

variable "deletion_protection" {
  default = false
}

variable "performance_insights_enabled" {
  default = true
}

variable "performance_insights_retention_period" {
  default = 7
}

variable "create_monitoring_role" {
  default = true
}

variable "monitoring_interval" {
  default = 60
}
