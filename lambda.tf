# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaExecutionPolicy"
  description = "IAM policy for Lambda to access AWS services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = "*" # Replace with specific ARNs for tighter security
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*" # Replace with specific ARNs for tighter security
      },
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.app_bucket.arn}",
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.my_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# DynamoDB Table
resource "aws_dynamodb_table" "my_table" {
  name           = "my-dynamodb-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Other configurations as needed
}

# Commented out code:
/*
resource "aws_lambda_function" "etl_function" {
  function_name = "my-etl-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  filename         = data.archive_file.lambda_packages["etl_function"].output_path
  source_code_hash = data.archive_file.lambda_packages["etl_function"].output_base64sha256

  environment {
    variables = {
      OUTPUT_BUCKET = var.app_bucket_name
      DYNAMODB_TABLE = aws_dynamodb_table.my_table.name 
    }
  }

  depends_on = [null_resource.package_lambdas]
}

# S3 Bucket Notification to Trigger Lambda
resource "aws_s3_bucket_notification" "input_bucket_notification" {
  bucket = var.app_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Allow S3 to Invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.etl_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.app_bucket.arn
}

resource "aws_lambda_function" "lambda_functions" {
  for_each = local.scripts

  function_name = each.key
  role          = aws_iam_role.lambda_role.arn
  handler       = each.value.handler
  runtime       = each.value.runtime

  filename         = data.archive_file.lambda_packages[each.key].output_path
  source_code_hash = data.archive_file.lambda_packages[each.key].output_base64sha256

  depends_on = [
    null_resource.package_lambdas
  ]
}

resource "aws_lambda_event_source_mapping" "sqs_consumer_trigger" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.lambda_functions["sqs_consumer"].function_name

  batch_size = 10
  enabled    = true
}

resource "aws_lambda_event_source_mapping" "kinesis_consumer_trigger" {
  event_source_arn  = aws_kinesis_stream.example_stream.arn
  function_name     = aws_lambda_function.lambda_functions["kinesis_consumer"].function_name

  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}
*/