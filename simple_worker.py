#!/usr/bin/env python3
"""
Simple Celery worker for testing
"""

import os
from celery import Celery

# Set environment variables
os.environ['AWS_REGION'] = 'eu-west-1'
os.environ['AWS_ACCESS_KEY_ID'] = 'AKIAYCG3NTKVNJBJVWIH'
os.environ['AWS_SECRET_ACCESS_KEY'] = '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'

# Create simple Celery app
app = Celery('wipsie-test')

# Configure for SQS
app.conf.update(
    broker_url='sqs://',
    broker_transport_options={
        'region': 'eu-west-1',
        'aws_access_key_id': 'AKIAYCG3NTKVNJBJVWIH',
        'aws_secret_access_key': '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',
        'queue_name_prefix': 'wipsie-',
    },
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
)


@app.task
def test_task(message):
    return f"Hello from Celery: {message}"


if __name__ == '__main__':
    print("🚀 Starting simple Celery worker...")
    app.worker_main(['worker', '--loglevel=info'])
