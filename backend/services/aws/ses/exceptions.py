"""
SES-specific exceptions
"""


class SESError(Exception):
    """Base exception for SES operations"""

    pass


class EmailSendError(SESError):
    """Raised when email sending fails"""

    pass


class EmailValidationError(SESError):
    """Raised when email validation fails"""

    pass


class SESQuotaExceededError(SESError):
    """Raised when SES sending quota is exceeded"""

    pass


class EmailTemplateError(SESError):
    """Raised when email template processing fails"""

    pass


class SESConfigurationError(SESError):
    """Raised when SES configuration is invalid"""

    pass
