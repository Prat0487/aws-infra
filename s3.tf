# main.tf (continued)

resource "aws_s3_bucket" "static_site_bucket" {
  bucket = var.bucket_name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name        = "StaticWebsiteBucket"
    Environment = "POC"
  }
}

resource "aws_s3_bucket_ownership_controls" "static_site_bucket_ownership" {
  bucket = aws_s3_bucket.static_site_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static_site_bucket_public_access" {
  bucket = aws_s3_bucket.static_site_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.static_site_bucket.id
  depends_on = [aws_s3_bucket.static_site_bucket, aws_s3_bucket_public_access_block.static_site_bucket_public_access]

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.static_site_bucket.arn}/*"
      }
    ]
  })
}
variable "bucket_name" {
  description = "s3_static_hosting_prateek_poc"
  type        = string
  default = "s3-static-hosting-prateek-poc"
}
# s3_objects.tf

# Upload index.html
resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.static_site_bucket.bucket
  key    = "index.html"
  source = "${path.module}/website/index.html"
  etag   = filemd5("${path.module}/website/index.html")
  content_type = "text/html"
  depends_on = [aws_s3_bucket.static_site_bucket]
}

# Upload error.html
resource "aws_s3_bucket_object" "error" {
  bucket = aws_s3_bucket.static_site_bucket.bucket
  key    = "error.html"
  source = "${path.module}/website/error.html"
  etag   = filemd5("${path.module}/website/error.html")
  content_type = "text/html"
  depends_on = [aws_s3_bucket.static_site_bucket]
}
