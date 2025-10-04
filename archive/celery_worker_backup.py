#!/usr/bin/env python3
"""
Celery worker to process SQS messages using organized AWS services
"""

import json
import logging
from datetime import datetime
from urllib.parse import quote_plus

from celery import Celery

from backend.core.config import settings
from backend.services.aws.ses.service import ses_service
from backend.services.aws.sqs.service import sqs_service

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
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-default'
            },
            'wipsie-data-polling': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-data-polling'
            },
            'wipsie-task-processing': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-task-processing'
            },
            'wipsie-notifications': {
                'url': f'https://sqs.{settings.AWS_REGION}.amazonaws.com/554510949034/wipsie-notifications'
            }
        }
    },
    task_default_queue='wipsie-default',
    task_routes={
        'celery_worker.process_data_polling': {'queue': 'wipsie-data-polling'},
        'celery_worker.process_task': {'queue': 'wipsie-task-processing'},
        'celery_worker.send_notification': {'queue': 'wipsie-notifications'},
        'celery_worker.notify_task_completion': {'queue': 'wipsie-notifications'},
        'celery_worker.process_email_queue': {'queue': 'wipsie-notifications'},
    },
    # Disable results backend to avoid queue creation issues
    result_backend=None,
    # Task serialization
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
)


@app.task(bind=True)
def process_default_message(self, message_data):
    """Process messages from the default queue"""
    logger.info(f"📨 Processing default message: {self.request.id}")

    try:
        # Parse the message if it's a string
        if isinstance(message_data, str):
            data = json.loads(message_data)
        else:
            data = message_data

        logger.info(
            f"📝 Message content: {data.get('message', 'No message field')}")
        logger.info(f"🆔 Task ID: {data.get('task_id', 'No task ID')}")
        logger.info(f"🔖 Task Type: {data.get('task_type', 'Unknown')}")

        # Simulate processing
        result = {
            'status': 'processed',
            'message_id': self.request.id,
            'processed_at': datetime.now().isoformat(),
            'original_data': data
        }

        logger.info(f"✅ Successfully processed message: {self.request.id}")
        return result

    except Exception as e:
        logger.error(f"❌ Error processing message {self.request.id}: {e}")
        raise self.retry(countdown=60, max_retries=3)


@app.task(bind=True)
def process_data_polling(self, polling_data):
    """Process data polling tasks"""
    logger.info(f"🔍 Processing data polling task: {self.request.id}")

    try:
        # Simulate data polling
        logger.info(
            f"📊 Polling data from source: {polling_data.get('source', 'unknown')}")

        # Mock data collection
        collected_data = {
            'timestamp': datetime.now().isoformat(),
            'source': polling_data.get('source', 'unknown'),
            'records_collected': 42,  # Mock number
            'status': 'success'
        }

        logger.info(f"✅ Data polling completed: {collected_data}")
        return collected_data

    except Exception as e:
        logger.error(f"❌ Data polling failed: {e}")
        raise self.retry(countdown=120, max_retries=2)


@app.task(bind=True)
def process_task(self, task_data):
    """Process general tasks"""
    logger.info(f"⚙️ Processing task: {self.request.id}")

    try:
        task_type = task_data.get('type', 'unknown')
        logger.info(f"🔧 Task type: {task_type}")

        # Process based on task type
        if task_type == 'data_analysis':
            result = {'analysis': 'completed',
                      'insights': ['insight1', 'insight2']}
        elif task_type == 'report_generation':
            result = {'report': 'generated',
                      'file_path': '/reports/report.pdf'}
        else:
            result = {'status': 'processed', 'type': task_type}

        logger.info(f"✅ Task completed: {result}")
        return result

    except Exception as e:
        logger.error(f"❌ Task processing failed: {e}")
        raise self.retry(countdown=90, max_retries=3)


@app.task(bind=True)
def send_notification(self, notification_data):
    """Send notifications via email and SQS"""
    logger.info(f"📢 Sending notification: {self.request.id}")

    try:
        recipient = notification_data.get('recipient', 'unknown')
        message = notification_data.get('message', 'No message')
        notification_type = notification_data.get('type', 'general')
        priority = notification_data.get('priority', 'medium')

        logger.info(f"👤 Recipient: {recipient}")
        logger.info(f"💬 Message: {message}")
        logger.info(f"🔖 Type: {notification_type}")

        # Send email notification using SES service
        email_result = None
        if '@' in recipient:  # If recipient looks like an email
            try:
                email_result = ses_service.send_notification_email(
                    recipient=recipient,
                    notification_type=notification_type,
                    title=f"Wipsie Notification: {notification_type}",
                    content=message,
                    priority=priority
                )
                logger.info("📧 Email notification sent via SES")
            except Exception as e:
                logger.warning(f"📧 Email sending failed: {e}")

        # Create notification result
        result = {
            'notification_sent': True,
            'recipient': recipient,
            'sent_at': datetime.now().isoformat(),
            'methods': [],
            'email_result': email_result
        }

        # Add email method if successful
        if email_result:
            result['methods'].append('email')

        # Could add other notification methods here (SMS, Slack, etc.)
        result['methods'].append('logged')

        logger.info("✅ Notification sent successfully")
        return result

    except Exception as e:
        logger.error(f"❌ Notification failed: {e}")
        raise self.retry(countdown=30, max_retries=5)


@app.task(bind=True)
def notify_task_completion(self, task_data):
    """Send task completion notifications"""
    logger.info(f"🎯 Sending task completion notification: {self.request.id}")

    try:
        task_id = task_data.get('task_id', self.request.id)
        task_type = task_data.get('task_type', 'unknown')
        status = task_data.get('status', 'completed')
        recipient = task_data.get('recipient', 'admin@wipsie.com')
        details = task_data.get('details', {})

        # Send task completion email
        email_result = ses_service.send_task_completion_email(
            recipient=recipient,
            task_id=task_id,
            task_type=task_type,
            status=status,
            details=details
        )

        logger.info(f"📧 Task completion email sent to {recipient}")

        return {
            'notification_type': 'task_completion',
            'task_id': task_id,
            'status': status,
            'email_sent': True,
            'email_message_id': email_result['message_id'],
            'sent_at': datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ Task completion notification failed: {e}")
        raise self.retry(countdown=60, max_retries=3)


@app.task(bind=True)
def process_email_queue(self, email_data):
    """Process email sending requests from queue"""
    logger.info(f"📧 Processing email queue: {self.request.id}")

    try:
        email_type = email_data.get('email_type', 'general')

        if email_type == 'notification':
            # Handle notification emails
            result = ses_service.send_notification_email(
                recipient=email_data['recipient'],
                notification_type=email_data['notification_type'],
                title=email_data['title'],
                content=email_data['content'],
                priority=email_data.get('priority', 'medium')
            )
        elif email_type == 'task_completion':
            # Handle task completion emails
            result = ses_service.send_task_completion_email(
                recipient=email_data['recipient'],
                task_id=email_data['task_id'],
                task_type=email_data['task_type'],
                status=email_data['status'],
                details=email_data['details']
            )
        else:
            # Handle general emails
            result = ses_service.send_email(
                to_emails=email_data['to_emails'],
                subject=email_data['subject'],
                body_text=email_data['body_text'],
                body_html=email_data.get('body_html'),
                sender_email=email_data.get('sender_email')
            )

        logger.info(f"📧 Email sent successfully: {result['message_id']}")
        return result

    except Exception as e:
        logger.error(f"❌ Email processing failed: {e}")
        raise self.retry(countdown=120, max_retries=3)


if __name__ == '__main__':
    # Start the worker
    app.start()
