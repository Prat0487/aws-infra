import json
import boto3
import os
import csv
from io import StringIO
from datetime import datetime
from collections import defaultdict, Counter

def lambda_handler(event, context):
    # Initialize AWS clients
    s3 = boto3.client('s3')
    dynamodb = boto3.resource('dynamodb')

    # Retrieve environment variables
    table_name = os.environ.get('DYNAMODB_TABLE')
    bucket = os.environ.get('OUTPUT_BUCKET')

    if not table_name or not bucket:
        print("Environment variables DYNAMODB_TABLE and OUTPUT_BUCKET must be set")
        return {
            'statusCode': 500,
            'body': json.dumps('Environment variables DYNAMODB_TABLE and OUTPUT_BUCKET must be set')
        }

    table = dynamodb.Table(table_name)
    timestamp = datetime.now().isoformat()

    try:
        # Extract the key from the event
        key = event['Records'][0]['s3']['object']['key']

        # Read the CSV file from S3
        response = s3.get_object(Bucket=bucket, Key=key)
        csv_content = response['Body'].read().decode('utf-8')

        # Read CSV content
        csv_reader = csv.DictReader(StringIO(csv_content))

        data = []
        for row in csv_reader:
            # Clean and convert 'Price (Euro)'
            price_str = row.get('Price (Euro)', '').replace(' Euro', '').strip()
            try:
                price = float(price_str)
            except ValueError:
                price = 0.0  # Default to 0.0 if conversion fails

            row['Price (Euro)'] = price

            # Clean and convert 'RAM (GB)'
            ram_str = row.get('RAM (GB)', '').replace('GB', '').strip()
            try:
                ram = float(ram_str)
            except ValueError:
                ram = 0.0  # Default to 0.0 if conversion fails

            row['RAM (GB)'] = ram

            data.append(row)

        if not data:
            print("No data found in CSV")
            return {
                'statusCode': 400,
                'body': json.dumps('No data found in CSV')
            }

        # Perform ETL operations

        # 1. Calculate average price by Company
        company_price_totals = defaultdict(float)
        company_price_counts = defaultdict(int)

        for row in data:
            company = row.get('Company', 'Unknown')
            price = row['Price (Euro)']
            company_price_totals[company] += price
            company_price_counts[company] += 1

        avg_price_by_company = []
        for company in company_price_totals:
            total_price = company_price_totals[company]
            count = company_price_counts[company]
            avg_price = total_price / count if count else 0.0
            avg_price_by_company.append({
                'Company': company,
                'Average Price (Euro)': avg_price
            })

        # 2. Calculate average RAM by CPU_Company
        cpu_ram_totals = defaultdict(float)
        cpu_ram_counts = defaultdict(int)

        for row in data:
            cpu_company = row.get('CPU_Company', 'Unknown')
            ram = row['RAM (GB)']
            cpu_ram_totals[cpu_company] += ram
            cpu_ram_counts[cpu_company] += 1

        avg_ram_by_cpu = []
        for cpu_company in cpu_ram_totals:
            total_ram = cpu_ram_totals[cpu_company]
            count = cpu_ram_counts[cpu_company]
            avg_ram = total_ram / count if count else 0.0
            avg_ram_by_cpu.append({
                'CPU_Company': cpu_company,
                'Average RAM (GB)': avg_ram
            })

        # 3. Count products by OpSys
        opsys_counts = Counter()
        for row in data:
            opsys = row.get('OpSys', 'Unknown')
            opsys_counts[opsys] += 1

        products_by_os = []
        for opsys, count in opsys_counts.items():
            products_by_os.append({
                'OpSys': opsys,
                'Count': count
            })

        # Combine results into a dictionary
        results = {
            'avg_price_by_company': avg_price_by_company,
            'avg_ram_by_cpu': avg_ram_by_cpu,
            'products_by_os': products_by_os
        }

        # Convert results to JSON
        output_json = json.dumps(results, indent=2)

        # Upload the result back to S3
        output_key = f"laptop_analysis_{timestamp}.json"
        s3.put_object(Bucket=bucket, Key=output_key, Body=output_json.encode('utf-8'))

        # Store metadata in DynamoDB
        item = {
            'id': str(hash(timestamp)),
            'timestamp': timestamp,
            'input_file': key,
            'output_file': output_key,
            'record_count': len(data)
        }
        table.put_item(Item=item)

        return {
            'statusCode': 200,
            'body': json.dumps('ETL job completed successfully')
        }

    except Exception as e:
        print(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('Error processing the event')
        }
