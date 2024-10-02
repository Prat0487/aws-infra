# Define the main SQS queue for order processing
resource "aws_sqs_queue" "order_queue" {
  name                        = "order-processing-queue"
  delay_seconds               = 0
  message_retention_seconds   = 86400  # 1 day
  visibility_timeout_seconds  = 30
  max_message_size            = 262144  # 256KB
  receive_wait_time_seconds   = 0

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_dlq.arn
    maxReceiveCount     = 5
  })
}

# Define IAM role for SQS producer (e.g., order creation service)
resource "aws_iam_role" "producer_role" {
  name = "sqs-producer-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach policy to producer role for sending messages to SQS
resource "aws_iam_role_policy" "producer_policy" {
  name = "sqs-producer-policy"
  role = aws_iam_role.producer_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sqs:SendMessage"
      Effect   = "Allow"
      Resource = aws_sqs_queue.order_queue.arn
    }]
  })
}

# Define IAM role for SQS consumer (e.g., order processing service)
resource "aws_iam_role" "consumer_role" {
  name = "sqs-consumer-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach policy to consumer role for receiving and deleting messages from SQS
resource "aws_iam_role_policy" "consumer_policy" {
  name = "sqs-consumer-policy"
  role = aws_iam_role.consumer_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Effect   = "Allow"
      Resource = aws_sqs_queue.order_queue.arn
    }]
  })
}

# Define Dead Letter Queue (DLQ) for handling failed messages
resource "aws_sqs_queue" "order_dlq" {
  name                      = "order-dead-letter-queue"
  message_retention_seconds = 1209600  # 14 days
}

# Attach a policy to the main queue to define access permissions
resource "aws_sqs_queue_policy" "order_queue_policy" {
  queue_url = aws_sqs_queue.order_queue.id
  policy    = data.aws_iam_policy_document.order_queue_policy.json
}

# Define the policy document for the main queue
data "aws_iam_policy_document" "order_queue_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [aws_sqs_queue.order_queue.arn]
  }
}
