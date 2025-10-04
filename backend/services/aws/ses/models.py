"""
SES data models and schemas
"""

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, EmailStr


class EmailMessage(BaseModel):
    """Standard email message format"""

    to_emails: List[EmailStr]
    subject: str
    body_text: str
    body_html: Optional[str] = None
    sender_email: Optional[EmailStr] = None
    reply_to: Optional[List[EmailStr]] = None
    priority: Optional[str] = "medium"
    message_type: Optional[str] = "general"


class EmailTemplate(BaseModel):
    """Email template configuration"""

    template_name: str
    subject_template: str
    text_template: str
    html_template: Optional[str] = None
    variables: Dict[str, Any] = {}


class NotificationEmail(BaseModel):
    """Notification email specific format"""

    recipient: EmailStr
    notification_type: str
    title: str
    content: str
    priority: str = "medium"
    metadata: Optional[Dict[str, Any]] = None


class TaskCompletionEmail(BaseModel):
    """Task completion notification format"""

    recipient: EmailStr
    task_id: str
    task_type: str
    status: str  # success, failed, warning
    details: Dict[str, Any]
    execution_time: Optional[float] = None
    error_message: Optional[str] = None


class EmailResponse(BaseModel):
    """Response model for sent emails"""

    message_id: str
    sender: str
    recipients: List[str]
    subject: str
    status: str
    timestamp: str
    delivery_status: Optional[str] = "sent"


class SESQuota(BaseModel):
    """SES sending quota information"""

    max_24_hour_send: float
    max_send_rate: float
    sent_last_24_hours: float
    send_data_points: List[Dict[str, Any]] = []
