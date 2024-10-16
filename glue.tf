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

resource "aws_iam_role_policy_attachment" "glue_s3_full_access" {
  role       = aws_iam_role.glue_service_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_service_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy" "glue_job_creation_policy" {
  name        = "GlueJobCreationPolicy"
  description = "Policy for creating Glue jobs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:CreateJob",
          "glue:GetJob",
          "glue:StartJobRun",
          "glue:UpdateJob"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_job_creation_policy_attachment" {
  role       = aws_iam_role.glue_service_role.id
  policy_arn = aws_iam_policy.glue_job_creation_policy.arn
}

resource "time_sleep" "wait_for_policy_propagation" {
  depends_on = [
    aws_iam_role_policy_attachment.glue_s3_full_access,
    aws_iam_role_policy_attachment.glue_service_role,
    aws_iam_role_policy_attachment.glue_job_creation_policy_attachment
  ]

  create_duration = "30s"
}
/*
resource "aws_glue_job" "example" {
  name     = "example-glue-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.app_bucket_name}/script.py"
  }
  
  default_arguments = {
    "--TempDir" = "s3://${var.app_bucket_name}/temp/"
    "--job-bookmark-option" = "job-bookmark-enable"
  }

  max_retries = 0
  timeout     = 2880
  glue_version = "3.0"

  execution_property {
    max_concurrent_runs = 1
  }

  worker_type = "G.1X"
  number_of_workers = 2

  depends_on = [
    aws_iam_role.glue_service_role,
    aws_iam_role_policy_attachment.glue_s3_full_access,
    aws_iam_role_policy_attachment.glue_service_role,
    aws_iam_role_policy_attachment.glue_job_creation_policy_attachment,
    time_sleep.wait_for_policy_propagation
  ]
}
*/

resource "aws_glue_catalog_database" "glue_database" {
  name = var.glue_database_name
}
resource "aws_glue_catalog_table" "employees_table" {
  database_name = aws_glue_catalog_database.glue_database.name
  name          = "employees"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "skip.header.line.count" = "1"
    "classification"         = "csv"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_bucket.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "employees"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = ","
      }
    }

    columns {
      name = "employee_id"
      type = "int"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "department"
      type = "string"
    }
    columns {
      name = "salary"
      type = "int"
    }
  }
}



resource "aws_s3_bucket" "data_bucket" {
  bucket = "your-unique-data-bucket-name"
}
