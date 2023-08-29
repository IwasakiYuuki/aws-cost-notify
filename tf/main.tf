variable "SLACK_WEBHOOK_URL" {
    type = string
}

variable "SCHEDULE_EXPRESSION" {
    type = string
    default = "cron(0 10 ? * MON *)"
}

provider aws {}

resource "aws_iam_policy" "cn_lambda_policy" {
  name = "cn_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ce:GetCostAndUsage"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role" "cn_lambda_role" {
  name = "cn_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cn_role_policy_attachment" {
  role = aws_iam_role.cn_lambda_role.name
  policy_arn = aws_iam_policy.cn_lambda_policy.arn
}

data "archive_file" "lambda" {
  type = "zip"
  source_dir = "../lambda"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "cn_lambda" {
  filename = "lambda_function_payload.zip"
  function_name = "cn_lambda"
  role = aws_iam_role.cn_lambda_role.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler = "main.lambda_handler"
  runtime = "python3.11"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.SLACK_WEBHOOK_URL
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_week" {
  name                = "every_week"
  schedule_expression = var.SCHEDULE_EXPRESSION
}

resource "aws_cloudwatch_event_target" "example" {
  rule      = aws_cloudwatch_event_rule.every_week.name
  arn       = aws_lambda_function.cn_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cn_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_week.arn
}
