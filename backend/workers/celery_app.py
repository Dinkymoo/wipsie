#!/usr/bin/env python3
"""
Celery Application Configuration
Centralized Celery setup with SQS broker
"""

import logging
from urllib.parse import quote_plus

from celery import Celery

from backend.core.config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Celery app
app = Celery('wipsie_worker')

# URL encode AWS credentials for broker URL
encoded_access_key = quote_plus(settings.AWS_ACCESS_KEY_ID or "")
encoded_secret_key = quote_plus(settings.AWS_SECRET_ACCESS_KEY or "")

# Configure Celery to use SQS as broker
app.conf.update(
    broker_url=f'sqs://{encoded_access_key}:{encoded_secret_key}@',
    broker_transport_options={
        'region': settings.AWS_REGION,
        'predefined_queues': {
            'wipsie-default': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-default'  # noqa: E501
            },
            'wipsie-data-polling': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-data-polling'  # noqa: E501
            },
            'wipsie-task-processing': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-task-processing'  # noqa: E501
            },
            'wipsie-notifications': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-notifications'  # noqa: E501
            }
        }
    },
    task_default_queue='wipsie-default',
    task_routes={
        'backend.workers.tasks.data_processing.*': {
            'queue': 'wipsie-data-polling'
        },
        'backend.workers.tasks.general.*': {
            'queue': 'wipsie-task-processing'
        },
        'backend.workers.tasks.notifications.*': {
            'queue': 'wipsie-notifications'
        },
        'backend.workers.tasks.email.*': {
            'queue': 'wipsie-notifications'
        },
    },
    # Disable results backend to avoid queue creation issues
    result_backend=None,
    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    # Auto-discover tasks from task modules
    include=[
        'backend.workers.tasks.data_processing',
        'backend.workers.tasks.general',
        'backend.workers.tasks.notifications',
        'backend.workers.tasks.email',
    ]
)

# Configure logging for Celery
app.log.setup_logging_subsystem(loglevel=logging.INFO)

logger.info("🚀 Celery app configured with SQS broker")
