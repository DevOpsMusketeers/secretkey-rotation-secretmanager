resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sm-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "iam-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

resource "aws_iam_policy" "iam_policy" {
  name        = "update_keys"
  path        = "/"
  description = "Policy to update access keys via Lambda"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ChangeKeys",
        "Action" : [
          "iam:ListUsers",
          "iam:GetAccessKeyLastUsed",
          "iam:ListAccessKeys",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "iam:CreateAccessKey"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_lambda_function" "dm_lambda" {
  function_name                  = var.function_name
  handler                        = "access_keys_rotation.lambda_handler"
  filename                       = var.filename
  memory_size                    = 128
  package_type                   = "Zip"
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.iam_for_lambda.arn
  runtime                        = "python3.9"
  source_code_hash               = filebase64sha256(var.filename)
  tags = {
    Name      = var.function_name
    CreatedBy = "Terraform"
  }
  timeout = 600

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dm_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
}
