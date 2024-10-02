import boto3
import uuid
import time
import json

kinesis_client = boto3.client('kinesis', region_name='us-east-1')

stream_name = 'example-stream'

def produce_data():
    record = {
        'event_id': str(uuid.uuid4()),
        'event_type': 'click',
        'timestamp': int(time.time())
    }
    kinesis_client.put_record(
        StreamName=stream_name,
        Data=json.dumps(record),
        PartitionKey='partition_key'
    )
    print(f"Produced record: {record}")

if __name__ == "__main__":
    for _ in range(10):
        produce_data()
        time.sleep(1)
