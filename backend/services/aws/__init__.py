"""
AWS services module
Provides access to Amazon Web Services integrations
"""

from .ses.service import SESService
from .sqs.service import SQSService

__all__ = ["SQSService", "SESService"]
