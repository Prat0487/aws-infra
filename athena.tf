resource "aws_s3_bucket" "athena_results_bucket" {
  bucket = "your-unique-athena-results-bucket-name"
}

resource "aws_s3_bucket_policy" "athena_results_bucket_policy" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:sts::014498640669:assumed-role/terraform-deploy/aws-go-sdk-1728499793657844400"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.athena_results_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.athena_results_bucket.id}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "athena_results_bucket_public_access" {
  bucket = aws_s3_bucket.athena_results_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_athena_workgroup" "athena_workgroup" {
  name = "AthenaPOCWorkgroup"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results_bucket.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  state = "ENABLED"
}
