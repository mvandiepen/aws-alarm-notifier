terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "demo-profile"
  region = "eu-central-1"
}

resource "aws_key_pair" "demo_key" {
  key_name   = "demokey"
  public_key = "ssh-rsa your-public-key-here example@email.com"
}

resource "aws_security_group" "allow_inbound_ssh" {
  name        = "allow_inbound_ssh"
  description = "Allow inbound SSH traffic"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "demo_server" {
  ami                     = "ami-05d34d340fb1d89e5"
  instance_type           = "t2.nano"
  key_name                = aws_key_pair.demo_key.key_name
  vpc_security_group_ids  = [aws_security_group.allow_inbound_ssh.id]

  tags = {
    Name = "demo-server"
  }
}

resource "aws_sns_topic" "alarm_notifier_topic" {
  name = "alarm-updates"
}

resource "aws_sns_topic_subscription" "sns_notifier_lambda_subscription" {
  topic_arn = aws_sns_topic.alarm_notifier_topic.arn
  endpoint  = aws_lambda_function.alarm_notifier_lambda.arn
  protocol  = "lambda"

  depends_on = [
    aws_sns_topic.alarm_notifier_topic,
    aws_lambda_function.alarm_notifier_lambda,
  ]
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_basic_execution" {
  name               = "lambda_basic_execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_basic_execution_policy" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_basic_execution_policy" {
  name = "lambda_basic_execution_policy"
  role = aws_iam_role.lambda_basic_execution.id
  policy = data.aws_iam_policy_document.lambda_basic_execution_policy.json
}

resource "aws_lambda_function" "alarm_notifier_lambda" {
  function_name    = "alarm-notifier"
  role             = aws_iam_role.lambda_basic_execution.arn
  filename         = "deployment-package.zip"
  source_code_hash = filebase64sha256("deployment-package.zip")
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  publish          = true

  tags = {
    Name = "alarm-notifier",
  }

  environment {
    variables = {
      slack_channel     = "#channel-name"
      slack_webhook_url = "your-webhook-url"
    }
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id = "AllowExecutionFromSNS"
  source_arn = aws_sns_topic.alarm_notifier_topic.arn
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_notifier_lambda.arn
  principal = "sns.amazonaws.com"

  depends_on = [
    aws_sns_topic_subscription.sns_notifier_lambda_subscription,
    aws_lambda_function.alarm_notifier_lambda,
  ]
}
