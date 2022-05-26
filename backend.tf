terraform {
  backend "s3"{
    bucket   = "ssm-windows-logs1"
    key      = "main-module/terraform.tfstate"
    region   = "us-east-1"
    profile  = "default"
    dynamodb_table = "emmanuel"
  }
}