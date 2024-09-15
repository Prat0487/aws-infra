resource "aws_iam_role" "glue_service_role" {
  name = "GlueServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "glue_s3_full_access" {
  name       = "attach_AmazonS3FullAccess"
  roles      = [aws_iam_role.glue_service_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
