#!/usr/bin/env python3
"""
Wipsie Worker Entry Point
Main entry point for running Celery workers
"""

from backend.workers.celery_app import app
import sys
from pathlib import Path

# Add the project root to Python path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


# Import all task modules to register them
from backend.workers.tasks import data_processing  # noqa: F401
from backend.workers.tasks import email  # noqa: F401
from backend.workers.tasks import general  # noqa: F401
from backend.workers.tasks import notifications  # noqa: F401

if __name__ == '__main__':
    # Start the worker
    app.start()
