provider "aws" {
  region = "eu-central-1"  
}

### S3 BUCKETS

resource "aws_s3_bucket" "source" {
  bucket = var.source_bucket
}

resource "aws_s3_bucket" "small" {
  bucket = var.small_bucket
}

resource "aws_s3_bucket" "medium" {
  bucket = var.medium_bucket
}

resource "aws_s3_bucket" "large" {
  bucket = var.large_bucket
}

### IAM ROLE

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

### IAM POLICY

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_s3_policy"
  description = "Policy for Lambda to access S3 buckets"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = "s3:*",
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}
### POLICY ATTACH

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

### LAMBDA FUNCTION


resource "aws_lambda_function" "s3_file_mover" {
  filename         = "function.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  
  environment {
    variables = {
      SMALL_BUCKET  = var.small_bucket
      MEDIUM_BUCKET = var.medium_bucket
      LARGE_BUCKET  = var.large_bucket
    }
  }
}

resource "aws_s3_bucket_notification" "source_bucket_notification" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_file_mover.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_file_mover.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}