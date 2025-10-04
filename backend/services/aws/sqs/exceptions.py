"""
SQS-specific exceptions
"""


class SQSError(Exception):
    """Base exception for SQS operations"""

    pass


class QueueNotFoundError(SQSError):
    """Raised when a queue is not found"""

    pass


class MessageSendError(SQSError):
    """Raised when message sending fails"""

    pass


class MessageReceiveError(SQSError):
    """Raised when message receiving fails"""

    pass


class MessageDeleteError(SQSError):
    """Raised when message deletion fails"""

    pass
