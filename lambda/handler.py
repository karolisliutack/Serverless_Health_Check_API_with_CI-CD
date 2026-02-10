import json
import os
import uuid
import logging
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'requests-db')
table = dynamodb.Table(table_name)


def lambda_handler(event, context):
    """
    Health check endpoint handler.

    Logs the request, validates input, saves to DynamoDB, and returns health status.
    """
    # Log the incoming request event
    logger.info(f"Received request: {json.dumps(event)}")

    try:
        # Parse request body for POST requests
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except json.JSONDecodeError:
                logger.error("Invalid JSON in request body")
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'status': 'error',
                        'message': 'Invalid JSON in request body'
                    })
                }

        # Input validation: POST requests must contain 'payload' key
        http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
        if http_method == 'POST':
            if 'payload' not in body:
                logger.warning("Missing 'payload' key in request body")
                return {
                    'statusCode': 400,
                    'headers': {'Content-Type': 'application/json'},
                    'body': json.dumps({
                        'status': 'error',
                        'message': "Missing required key: 'payload'"
                    })
                }

        # Generate unique ID and timestamp
        request_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()

        # Prepare item for DynamoDB
        item = {
            'id': request_id,
            'timestamp': timestamp,
            'method': http_method,
            'path': event.get('rawPath', '/health'),
            'source_ip': event.get('requestContext', {}).get('http', {}).get('sourceIp', 'unknown'),
            'user_agent': event.get('headers', {}).get('user-agent', 'unknown'),
            'environment': os.environ.get('ENVIRONMENT', 'unknown')
        }

        # Add payload if present
        if body:
            item['request_body'] = body

        # Save to DynamoDB
        table.put_item(Item=item)
        logger.info(f"Saved request to DynamoDB with ID: {request_id}")

        # Return success response
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'status': 'healthy',
                'message': 'Request processed and saved.',
                'request_id': request_id
            })
        }

    except ClientError as e:
        logger.error(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'status': 'error',
                'message': 'Failed to save request to database'
            })
        }
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'status': 'error',
                'message': 'Internal server error'
            })
        }
