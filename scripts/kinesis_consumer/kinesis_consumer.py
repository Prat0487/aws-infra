import boto3
import json

kinesis_client = boto3.client('kinesis', region_name='us-east-1')

stream_name = 'example-stream'

def consume_data():
    response = kinesis_client.describe_stream(StreamName=stream_name)
    shard_id = response['StreamDescription']['Shards'][0]['ShardId']
    shard_iterator = kinesis_client.get_shard_iterator(
        StreamName=stream_name,
        ShardId=shard_id,
        ShardIteratorType='LATEST'
    )['ShardIterator']

    while True:
        record_response = kinesis_client.get_records(ShardIterator=shard_iterator, Limit=10)
        records = record_response['Records']
        if records:
            for record in records:
                data = json.loads(record['Data'])
                print(f"Consumed record: {data}")
        shard_iterator = record_response['NextShardIterator']

if __name__ == "__main__":
    consume_data()
