locals {
  scripts = {
    "etl_function" = {
      path    = "${path.module}/scripts/etl_function"
      handler = "lambda_function.lambda_handler"
      runtime = "python3.8"
    },
    "kinesis_producer" = {
      path    = "${path.module}/scripts/kinesis_producer"
      handler = "producer_script.lambda_handler"
      runtime = "python3.9"
    },
    "kinesis_consumer" = {
      path    = "${path.module}/scripts/kinesis_consumer"
      handler = "consumer_script.lambda_handler"
      runtime = "python3.9"
    },
    "sqs_producer" = {
      path    = "${path.module}/scripts/sqs_producer"
      handler = "producer_script.lambda_handler"
      runtime = "python3.9"
    },
    "sqs_consumer" = {
      path    = "${path.module}/scripts/sqs_consumer"
      handler = "consumer_script.lambda_handler"
      runtime = "python3.9"
    }
  }
}
