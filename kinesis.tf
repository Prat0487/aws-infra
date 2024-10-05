  // Uncommented resources

  // S3 bucket for Kinesis Firehose
  resource "aws_s3_bucket" "kinesis_firehose_bucket" {
    bucket        = "kinesis-firehose-example-bucket-123456" # Replace with a unique bucket name
    force_destroy = true

    versioning {
      enabled = true
    }
  }

  // Commented resources

  /*
  // Kinesis stream
  resource "aws_kinesis_stream" "example_stream" {
    name             = "example-stream"
    shard_count      = 1
    retention_period = 24
  }

  // S3 bucket ACL
  resource "aws_s3_bucket_acl" "kinesis_firehose_bucket_acl" {
    bucket = aws_s3_bucket.kinesis_firehose_bucket.id
    acl    = "private"
  }

  // IAM role for Firehose
  resource "aws_iam_role" "firehose_role" {
    name = "firehose_delivery_role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }]
    })
  }

  // IAM policy for Firehose
  resource "aws_iam_policy" "firehose_policy" {
    name        = "firehose_policy"
    description = "Policy for Firehose to access Kinesis and S3"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListStreams"
          ],
          Resource = aws_kinesis_stream.example_stream.arn
        },
        {
          Effect = "Allow",
          Action = [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ],
          Resource = "${aws_s3_bucket.kinesis_firehose_bucket.arn}/*"
        },
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }

  // Attach IAM policy to IAM role
  resource "aws_iam_role_policy_attachment" "firehose_attach" {
    role       = aws_iam_role.firehose_role.name
    policy_arn = aws_iam_policy.firehose_policy.arn
  }

  // Kinesis Firehose delivery stream
  resource "aws_kinesis_firehose_delivery_stream" "example_firehose" {
    name        = "example-firehose-stream"
    destination = "extended_s3"

    kinesis_source_configuration {
      kinesis_stream_arn = aws_kinesis_stream.example_stream.arn
      role_arn           = aws_iam_role.firehose_role.arn
    }

    extended_s3_configuration {
      role_arn            = aws_iam_role.firehose_role.arn
      bucket_arn          = aws_s3_bucket.kinesis_firehose_bucket.arn
      compression_format  = "UNCOMPRESSED"
      prefix              = "firehose-data/"
      error_output_prefix = "firehose-errors/"
    }
  }

  // Athena database
  resource "aws_athena_database" "example_database" {
    name   = "kinesis_database"
    bucket = aws_s3_bucket.kinesis_firehose_bucket.bucket
  }

  // Athena workgroup
  resource "aws_athena_workgroup" "example_workgroup" {
    name        = "example-workgroup"
    state       = "ENABLED"
    description = "Example Athena workgroup"
  }

  // Run producer script
  resource "null_resource" "run_producer" {
    provisioner "local-exec" {
      command = "powershell.exe -ExecutionPolicy Bypass -File C:/GitRepo/aws-infra/kinesis-scripts/consumer.py"
    }

    triggers = { always_run = timestamp() }
    depends_on = [aws_kinesis_stream.example_stream]
  }

  // Run consumer script
  resource "null_resource" "run_consumer" {
    provisioner "local-exec" {
      command     = "python ${path.module}/consumer.py"
      interpreter = ["C:\\Windows\\System32\\cmd.exe", "/C"]
    }
    triggers = { always_run = timestamp() }
    depends_on = [aws_kinesis_stream.example_stream]
  }
  */