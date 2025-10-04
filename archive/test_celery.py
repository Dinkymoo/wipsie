#!/usr/bin/env python3
"""
Test Celery configuration for SQS
"""

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

print("🔍 Testing Celery SQS Configuration...")

# Test environment variables
print(f"AWS_REGION: {os.getenv('AWS_REGION')}")
print(f"AWS_ACCESS_KEY_ID: {os.getenv('AWS_ACCESS_KEY_ID')}")
print(
    f"AWS_SECRET_ACCESS_KEY: {'*' * 20 if os.getenv('AWS_SECRET_ACCESS_KEY') else 'NOT SET'}")

# Test basic imports
try:
    from backend.core.config import settings
    print(f"✅ Settings loaded - Region: {settings.AWS_REGION}")
    print(f"✅ SQS Queue Prefix: {settings.SQS_QUEUE_PREFIX}")
    print(f"✅ Broker URL: {settings.CELERY_BROKER_URL}")
except Exception as e:
    print(f"❌ Settings error: {e}")
    exit(1)

# Test Celery app creation
try:
    from celery import Celery

    # Create a simple Celery app for testing
    test_app = Celery('test')
    test_app.conf.update(
        broker_url='sqs://',
        broker_transport_options={
            'region': settings.AWS_REGION,
            'aws_access_key_id': settings.AWS_ACCESS_KEY_ID,
            'aws_secret_access_key': settings.AWS_SECRET_ACCESS_KEY,
            'queue_name_prefix': 'wipsie-test-',
        }
    )
    print("✅ Basic Celery SQS configuration successful")

except Exception as e:
    print(f"❌ Celery configuration error: {e}")
    exit(1)

# Test actual app import
try:
    from backend.core.celery_app import celery_app
    print("✅ Celery app imported successfully")
    print(f"✅ App broker: {celery_app.conf.broker_url}")

except Exception as e:
    print(f"❌ Celery app import error: {e}")
    print("This might be the issue preventing the worker from starting")

print("\n🎯 If all tests pass, try starting the worker again!")
