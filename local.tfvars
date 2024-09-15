
# General
environment = "local"
region      = "us-east-1"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# EC2
instance_type = "t2.micro"
key_name      = "my-key-pair"

# RDS
db_instance_class    = "db.t3.micro"
db_name              = "mydb"
db_username          = "admin"
db_password          = "changeme"
db_allocated_storage = 20

# S3
bucket_name = "my-local-bucket"

# Route53
domain_name = "example.com"

# CloudFront
cf_price_class = "PriceClass_100"

# Lambda
lambda_runtime = "nodejs14.x"

# API Gateway
api_gateway_stage_name = "dev"

# CloudWatch
log_retention_in_days = 30

# SNS
sns_topic_name = "my-local-topic"

# SQS
sqs_queue_name = "my-local-queue"

# DynamoDB
dynamodb_table_name = "my-local-table"
dynamodb_read_capacity  = 5
dynamodb_write_capacity = 5

# Elastic Beanstalk
eb_solution_stack_name = "64bit Amazon Linux 2 v3.4.13 running Python 3.8"
eb_instance_type       = "t2.micro"

# ECS
ecs_cluster_name = "my-local-cluster"
ecs_task_cpu     = "256"
ecs_task_memory  = "512"

# EKS
eks_cluster_version = "1.21"
eks_node_group_instance_types = ["t3.medium"]

# ElastiCache
elasticache_node_type  = "cache.t3.micro"
elasticache_num_nodes  = 1

# Elasticsearch
elasticsearch_instance_type = "t3.small.elasticsearch"
elasticsearch_version       = "7.10"

# Kinesis
kinesis_stream_name = "my-local-stream"
kinesis_shard_count = 1

# Step Functions
step_functions_name = "my-local-state-machine"

# WAF
waf_rule_name = "my-local-waf-rule"

# Cognito
cognito_user_pool_name = "my-local-user-pool"

# Glue
glue_job_name = "my-local-glue-job"

# Athena
athena_database_name = "my_local_database"

# QuickSight
quicksight_user_name = "my-local-quicksight-user"

# Redshift
redshift_cluster_type    = "single-node"
redshift_node_type       = "dc2.large"
redshift_database_name   = "mydb"
redshift_master_username = "admin"
redshift_master_password = "Changeme1"

# SageMaker
sagemaker_notebook_instance_type = "ml.t2.medium"

# IoT Core
iot_thing_name = "my-local-iot-thing"
