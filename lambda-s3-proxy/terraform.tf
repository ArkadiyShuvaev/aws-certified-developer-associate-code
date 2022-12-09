# IAM role for S3 Proxy
resource "aws_iam_role" "s3_proxy_execution_role" {
  name = "${var.s3_proxy_service_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

  tags = {
    Service   = var.s3_proxy_service_name
    CreatedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "s3_proxy" {
  role       = aws_iam_role.s3_proxy_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "s3_proxy" {
  name        = "${var.s3_proxy_service_name}"
  path        = "/"
  description = "The policy for ${var.s3_proxy_service_name}."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    CreatedBy = "Terraform",
    ServiceName = "${var.s3_proxy_service_name}"
  }

}

# Security Group for S3 Proxy
resource "aws_security_group" "s3_proxy" {
  name        = var.s3_proxy_service_name
  vpc_id      = var.vpc_id
  description = "Security group of the service ${var.s3_proxy_service_name}"

  egress {
    description = "Allow connections to all hosts to connect to S3."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  tags = {
    Service   = var.s3_proxy_service_name
    CreatedBy = "Terraform"
  }
}

# Lambda function for S3 Proxy
resource "aws_lambda_function" "s3_proxy" {
  function_name    = var.s3_proxy_service_name
  description      = "The function proxies requests to the '/public' and '/.well-known' destinations."
  filename         = "${path.module}/index.zip"
  runtime          = "nodejs16.x"
  handler          = "index.handler"
  source_code_hash = data.archive_file.archived_file.output_base64sha256
  role             = aws_iam_policy.s3_proxy.arn
  memory_size      = 128
  timeout          = 10 #seconds
  architectures    = ["arm64"]

  environment {
    variables = {
        public_bucket_name = "bucket-name"
    }
  }

  vpc_config {
   subnet_ids = var.private_subnets
    security_group_ids = [ aws_security_group.s3_proxy.id ]
  }

  tags = {
    CreatedBy = "Terraform",
    ServiceName = var.s3_proxy_service_name
  }
}

data "archive_file" "archived_file" {
  type        = "zip"
  source_file = "${path.module}/index.js"
  output_path = "${path.module}/index.zip"
}

# Allow ALB to call this Lambda
resource "aws_lambda_permission" "alb" {
  statement_id = "AllowExecutionFromALB"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_proxy.function_name
  principal = "elasticloadbalancing.amazonaws.com"
  source_arn = aws_lb_target_group.tg_to_s3_proxy.arn
}


resource "aws_lb_target_group" "tg_to_s3_proxy" {
  name        = "s3-proxy-tg"
  target_type = "lambda"
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group_attachment" "s3_proxy" {
  target_group_arn = aws_lb_target_group.tg_to_s3_proxy.arn
  target_id = aws_lambda_function.s3_proxy.arn
}
