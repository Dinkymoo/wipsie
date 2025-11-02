#!/usr/bin/env python3
"""
Start Celery Worker
Production script to start Celery workers
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


def start_worker():
    """Start the Celery worker"""
    # Import after path setup
    from workers import celery_app

    print("🚀 Starting Wipsie Celery Worker...")
    print("📋 Available Queues:")
    print("   • wipsie-default (general messages)")
    print("   • wipsie-data-polling (data processing)")
    print("   • wipsie-task-processing (general tasks)")
    print("   • wipsie-notifications (emails & alerts)")
    print()

    # Start worker with optimized settings
    celery_app.worker_main(
        [
            "worker",
            "--loglevel=info",
            "--concurrency=4",
            "--max-tasks-per-child=1000",
            "--time-limit=300",
            "--soft-time-limit=240",
        ]
    )


if __name__ == "__main__":
    start_worker()
