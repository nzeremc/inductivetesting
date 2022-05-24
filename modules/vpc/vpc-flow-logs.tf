# Create cloudwatch log group for vpc flow logs
resource "aws_cloudwatch_log_group" "cw_log_group" {
  count             = var.create_flow_logs && var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? 1 : 0
  name              = "${var.network_name}-flow-log-group"
  retention_in_days = var.flow_logs_retention

  tags = merge({
    Name = "${var.network_name}-flow-logs-group"
  }, var.tags)
}

# Create IAM role for VPC flow logs
resource "aws_iam_role" "flow_logs_role" {
  count = var.create_flow_logs && var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? 1 : 0
  name  = "${var.network_name}-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = merge({
    Name = "${var.network_name}-flow-logs-role"
  }, var.tags)
}

# Create IAM policy for VPC flow logs role
resource "aws_iam_role_policy" "flow_logs_policy" {
  count = var.create_flow_logs && var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? 1 : 0
  name  = "${var.network_name}-flow-logs-policy"
  role  = aws_iam_role.flow_logs_role[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "random_id" "id" {
  byte_length = 8
}

# Create S3 bucket for flow logs storage
resource "aws_s3_bucket" "flow_logs_bucket" {
  count         = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket        = "${var.network_name}-flow-logs-${random_id.id.hex}"
  acl           = "private"
  force_destroy = var.s3_force_destroy


  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSSLRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.network_name}-flow-logs-${random_id.id.hex}",
        "arn:aws:s3:::${var.network_name}-flow-logs-${random_id.id.hex}/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY

  tags = merge({
    Name = "${var.network_name}-flow-logs-${random_id.id.hex}"
  }, var.tags)
}

resource "aws_s3_bucket_public_access_block" "flow_logs_bucket" {
  count                   = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket                  = join(",", aws_s3_bucket.flow_logs_bucket.*.id)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  flow_logs_log_group_arn = var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? aws_cloudwatch_log_group.cw_log_group[0].arn : var.flow_logs_cw_log_group_arn
  flow_logs_bucket_arn    = var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? aws_s3_bucket.flow_logs_bucket[0].arn : var.flow_logs_bucket_arn
}

# Create VPC flow logs
resource "aws_flow_log" "flow_logs" {
  count                = var.create_flow_logs ? 1 : 0
  iam_role_arn         = var.flow_logs_destination == "cloud-watch-logs" ? aws_iam_role.flow_logs_role[0].arn : ""
  log_destination      = var.flow_logs_destination == "cloud-watch-logs" ? local.flow_logs_log_group_arn : local.flow_logs_bucket_arn
  log_destination_type = var.flow_logs_destination
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-flow-logs"
  }, var.tags)
}