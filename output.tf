# Output
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server_new.public_ip
}
# outputs.tf

output "api_url" {
  description = "Invoke URL of the deployed API Gateway"
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}"
}

/*
output "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream"
  value       = aws_kinesis_stream.example_stream.name
}

output "firehose_stream_name" {
  description = "Name of the Kinesis Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.example_firehose.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Firehose delivery"
  value       = aws_s3_bucket.kinesis_firehose_bucket.bucket
}
*/
# outputs.tf

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "data_bucket_name" {
  value = aws_s3_bucket.data_bucket.bucket
}

output "glue_database_name" {
  value = aws_glue_catalog_database.glue_database.name
}

output "athena_workgroup_name" {
  value = aws_athena_workgroup.athena_workgroup.name
}


