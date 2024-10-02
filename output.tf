# Output
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}
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