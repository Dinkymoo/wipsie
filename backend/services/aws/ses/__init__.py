"""
SES service module  
Amazon Simple Email Service integration
"""

from .exceptions import EmailSendError, SESError
from .models import EmailMessage, EmailTemplate
from .service import SESService

__all__ = [
    'SESService',
    'EmailMessage',
    'EmailTemplate',
    'SESError',
    'EmailSendError'
]
