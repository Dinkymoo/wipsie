"""
Notification Tasks
Handle various types of notifications and alerts
"""

import logging
from datetime import datetime

from ..celery_app import app
from .email import send_notification_email, send_task_completion_email

logger = logging.getLogger(__name__)


@app.task(bind=True)
def send_notification(self, notification_data):
    """Send notifications via multiple channels"""
    logger.info(f"📢 Sending notification: {self.request.id}")

    try:
        notification_type = notification_data.get('type', 'general')
        recipient = notification_data.get('recipient', 'unknown')
        message = notification_data.get('message', 'No message')
        priority = notification_data.get('priority', 'medium')
        channels = notification_data.get('channels', ['email', 'log'])

        logger.info(f"👤 Recipient: {recipient}")
        logger.info(f"💬 Message: {message}")
        logger.info(f"🔖 Type: {notification_type}")
        logger.info(f"📡 Channels: {channels}")

        results = []

        # Send email notification
        if 'email' in channels and '@' in recipient:
            try:
                email_result = send_notification_email.delay({
                    'recipient': recipient,
                    'message': message,
                    'type': notification_type,
                    'priority': priority
                })
                results.append({
                    'channel': 'email',
                    'status': 'queued',
                    'task_id': email_result.id
                })
                logger.info("📧 Email notification queued")
            except Exception as e:
                logger.warning(f"📧 Email notification failed: {e}")
                results.append({
                    'channel': 'email',
                    'status': 'failed',
                    'error': str(e)
                })

        # Log notification (always available)
        if 'log' in channels:
            logger.info(f"📝 LOG NOTIFICATION: {message}")
            results.append({
                'channel': 'log',
                'status': 'sent',
                'logged_at': datetime.now().isoformat()
            })

        # Could add more channels here (SMS, Slack, etc.)
        if 'slack' in channels:
            # Placeholder for Slack integration
            results.append({
                'channel': 'slack',
                'status': 'not_implemented',
                'message': 'Slack integration coming soon'
            })

        notification_result = {
            'notification_id': self.request.id,
            'type': notification_type,
            'recipient': recipient,
            'sent_at': datetime.now().isoformat(),
            'channels_attempted': channels,
            'results': results,
            'priority': priority
        }

        logger.info("✅ Notification processing completed")
        return notification_result

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

        # Queue task completion email
        email_task = send_task_completion_email.delay({
            'task_id': task_id,
            'task_type': task_type,
            'status': status,
            'recipient': recipient,
            'details': details
        })

        logger.info(f"📧 Task completion email queued for {recipient}")

        return {
            'notification_type': 'task_completion',
            'task_id': task_id,
            'status': status,
            'email_task_id': email_task.id,
            'sent_at': datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ Task completion notification failed: {e}")
        raise self.retry(countdown=60, max_retries=3)


@app.task(bind=True)
def send_alert(self, alert_data):
    """Send high-priority alerts"""
    logger.info(f"🚨 Sending alert: {self.request.id}")

    try:
        alert_type = alert_data.get('type', 'general')
        severity = alert_data.get('severity', 'medium')
        message = alert_data.get('message', 'Alert triggered')
        recipients = alert_data.get('recipients', ['admin@wipsie.com'])

        logger.warning(f"🚨 ALERT: {alert_type} - {message}")

        alert_results = []

        for recipient in recipients:
            try:
                # Send immediate notification for alerts
                notification_result = send_notification.delay({
                    'type': f'alert_{alert_type}',
                    'recipient': recipient,
                    'message': f"🚨 ALERT: {message}",
                    'priority': 'high',
                    'channels': ['email', 'log']
                })

                alert_results.append({
                    'recipient': recipient,
                    'status': 'queued',
                    'task_id': notification_result.id
                })

            except Exception as e:
                logger.error(f"❌ Alert failed for {recipient}: {e}")
                alert_results.append({
                    'recipient': recipient,
                    'status': 'failed',
                    'error': str(e)
                })

        return {
            'alert_id': self.request.id,
            'type': alert_type,
            'severity': severity,
            'message': message,
            'recipients_count': len(recipients),
            'results': alert_results,
            'triggered_at': datetime.now().isoformat()
        }

    except Exception as e:
        logger.error(f"❌ Alert processing failed: {e}")
        raise self.retry(countdown=15, max_retries=3)
