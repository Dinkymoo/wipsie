"""
Email Tasks
Handle email sending, notifications, and communication
"""

import logging
from datetime import datetime

from backend.services.aws.ses.service import ses_service

from ..celery_app import app

logger = logging.getLogger(__name__)


@app.task(bind=True)
def send_notification_email(self, notification_data):
    """Send notifications via email using SES"""
    logger.info(f"📧 Sending notification email: {self.request.id}")

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

        logger.info("✅ Email notification sent successfully")
        return result

    except Exception as e:
        logger.error(f"❌ Email notification failed: {e}")
        raise self.retry(countdown=30, max_retries=5)


@app.task(bind=True)
def send_task_completion_email(self, task_data):
    """Send task completion notifications"""
    logger.info(f"🎯 Sending task completion email: {self.request.id}")

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
        logger.error(f"❌ Task completion email failed: {e}")
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
