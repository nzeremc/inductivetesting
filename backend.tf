terraform {
  backend "s3"{
    bucket   = "multiaccounts3"
    key      = "main-module/terraform.tfstate"
    region   = "us-east-1"
    profile  = "default"
    dynamodb_table = "emm"
  }
}