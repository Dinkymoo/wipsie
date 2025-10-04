"""
Amazon SES (Simple Email Service) integration
"""

from datetime import (
    datetime,
)
from typing import (
    Any,
    Dict,
    List,
    Optional,
)

import boto3

from backend.core.config import (
    settings,
)


class SESService:
    """Service for sending emails via Amazon SES"""

    def __init__(self):
        self.ses = boto3.client(
            "ses",
            region_name=settings.AWS_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        )

        # Default sender (you'll need to verify this in SES)
        self.default_sender = "noreply@wipsie.com"

    def send_email(
        self,
        to_emails: List[str],
        subject: str,
        body_text: str,
        body_html: Optional[str] = None,
        sender_email: Optional[str] = None,
        reply_to: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Send an email via SES"""

        sender = sender_email or self.default_sender

        # Prepare email structure
        destination = {"ToAddresses": to_emails}

        if reply_to:
            destination["ReplyToAddresses"] = reply_to

        message = {
            "Subject": {"Data": subject, "Charset": "UTF-8"},
            "Body": {"Text": {"Data": body_text, "Charset": "UTF-8"}},
        }

        if body_html:
            message["Body"]["Html"] = {"Data": body_html, "Charset": "UTF-8"}

        # Send email
        response = self.ses.send_email(
            Source=sender, Destination=destination, Message=message
        )

        return {
            "message_id": response["MessageId"],
            "sender": sender,
            "recipients": to_emails,
            "subject": subject,
            "status": "sent",
            "timestamp": datetime.now().isoformat(),
        }

    def send_notification_email(
        self,
        recipient: str,
        notification_type: str,
        title: str,
        content: str,
        priority: str = "medium",
    ) -> Dict[str, Any]:
        """Send a notification email with standard formatting"""

        # Create HTML content
        html_body = f"""
        <html>
        <body>
            <h2>🔔 {title}</h2>
            <p><strong>Type:</strong> {notification_type}</p>
            <p><strong>Priority:</strong> {priority.upper()}</p>
            <hr>
            <div>{content}</div>
            <hr>
            <p><small>
                Sent from Wipsie System at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            </small></p>
        </body>
        </html>
        """

        # Create text version
        text_body = f"""
        🔔 {title}
        
        Type: {notification_type}
        Priority: {priority.upper()}
        
        {content}
        
        ---
        Sent from Wipsie System at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        """

        subject = f"[{priority.upper()}] {title}"

        return self.send_email(
            to_emails=[recipient],
            subject=subject,
            body_text=text_body,
            body_html=html_body,
        )

    def send_task_completion_email(
        self,
        recipient: str,
        task_id: str,
        task_type: str,
        status: str,
        details: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Send task completion notification"""

        emoji = "✅" if status == "success" else "❌"
        title = f"{emoji} Task {status.title()}: {task_type}"

        content = f"""
        <p><strong>Task ID:</strong> {task_id}</p>
        <p><strong>Status:</strong> {status}</p>
        <p><strong>Details:</strong></p>
        <ul>
        """

        for key, value in details.items():
            content += f"<li><strong>{key}:</strong> {value}</li>"

        content += "</ul>"

        return self.send_notification_email(
            recipient=recipient,
            notification_type="task_completion",
            title=title,
            content=content,
            priority="high" if status == "failed" else "medium",
        )

    def get_sending_quota(self) -> Dict[str, Any]:
        """Get SES sending quota and statistics"""

        quota = self.ses.get_send_quota()
        stats = self.ses.get_send_statistics()

        return {
            "max_24_hour_send": quota["Max24HourSend"],
            "max_send_rate": quota["MaxSendRate"],
            "sent_last_24_hours": quota["SentLast24Hours"],
            "send_data_points": stats.get("SendDataPoints", []),
        }


# Global instance
ses_service = SESService()
