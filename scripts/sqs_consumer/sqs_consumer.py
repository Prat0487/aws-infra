import boto3
import json
import time

sqs = boto3.client('sqs', region_name='us-east-1')

queue_url = '<Your Order Queue URL>'

while True:
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=10,
        WaitTimeSeconds=20,  # Long polling
        MessageAttributeNames=['All'],
    )

    messages = response.get('Messages', [])

    if not messages:
        print("No messages received. Waiting...")
        continue

    for message in messages:
        # Process the message
        body = json.loads(message['Body'])
        print(f"Processing order {body['order_id']} for customer {body['customer_id']}")

        # TODO: Add order processing logic here

        # Delete the message from the queue after processing
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )

    # Throttle processing if needed
    time.sleep(1)
