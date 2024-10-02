import boto3
import json

sqs = boto3.client('sqs', region_name='us-east-1')

queue_url = '<Your Order Queue URL>'

order = {
    'order_id': '12345',
    'customer_id': '67890',
    'items': [
        {'product_id': '111', 'quantity': 2},
        {'product_id': '222', 'quantity': 1},
    ],
    'total': 299.99
}

response = sqs.send_message(
    QueueUrl=queue_url,
    MessageBody=json.dumps(order),
    MessageAttributes={
        'OrderType': {
            'StringValue': 'Standard',
            'DataType': 'String'
        }
    }
)

print(f"Message ID: {response['MessageId']}")
