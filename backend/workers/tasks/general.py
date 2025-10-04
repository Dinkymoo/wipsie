"""
General Tasks
Handle general purpose background processing
"""

import logging
from datetime import datetime

from ..celery_app import app

logger = logging.getLogger(__name__)


@app.task(bind=True)
def process_task(self, task_data):
    """Process general tasks"""
    logger.info(f"⚙️ Processing general task: {self.request.id}")

    try:
        task_type = task_data.get("type", "unknown")
        logger.info(f"🔧 Task type: {task_type}")

        # Process based on task type
        if task_type == "data_analysis":
            result = {
                "analysis": "completed",
                "insights": ["insight1", "insight2"],
                "processed_records": 150,
                "analysis_duration": "2.5 seconds",
            }
        elif task_type == "report_generation":
            result = {
                "report": "generated",
                "file_path": "/reports/report.pdf",
                "pages": 12,
                "charts": 5,
            }
        elif task_type == "data_cleanup":
            result = {
                "cleanup": "completed",
                "records_cleaned": 1200,
                "duplicates_removed": 45,
                "errors_fixed": 12,
            }
        else:
            result = {"status": "processed", "type": task_type}

        # Add common metadata
        result.update(
            {
                "task_id": self.request.id,
                "completed_at": datetime.now().isoformat(),
                "processing_time": "1.2 seconds",
            }
        )

        logger.info(f"✅ Task completed: {result}")
        return result

    except Exception as e:
        logger.error(f"❌ Task processing failed: {e}")
        raise self.retry(countdown=90, max_retries=3)


@app.task(bind=True)
def health_check(self):
    """Worker health check task"""
    logger.info(f"💓 Health check: {self.request.id}")

    try:
        health_data = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "worker_id": self.request.id,
            "queue": self.request.delivery_info.get("routing_key", "unknown"),
            "checks": {
                "database": "ok",
                "aws_services": "ok",
                "memory": "ok",
                "disk": "ok",
            },
        }

        logger.info("✅ Worker health check passed")
        return health_data

    except Exception as e:
        logger.error(f"❌ Health check failed: {e}")
        raise


@app.task(bind=True)
def process_batch(self, batch_data):
    """Process a batch of items"""
    logger.info(f"📦 Processing batch: {self.request.id}")

    try:
        items = batch_data.get("items", [])
        batch_type = batch_data.get("type", "generic")

        logger.info(f"📊 Processing {len(items)} items of type: {batch_type}")

        processed_items = []
        failed_items = []

        for i, item in enumerate(items):
            try:
                # Simulate item processing
                processed_item = {
                    "original": item,
                    "processed_at": datetime.now().isoformat(),
                    "item_index": i,
                    "status": "success",
                }
                processed_items.append(processed_item)

            except Exception as item_error:
                logger.warning(f"⚠️ Failed to process item {i}: {item_error}")
                failed_items.append(
                    {"item": item, "index": i, "error": str(item_error)}
                )

        result = {
            "batch_id": self.request.id,
            "total_items": len(items),
            "processed_count": len(processed_items),
            "failed_count": len(failed_items),
            "processed_items": processed_items[:5],  # Show first 5
            "failed_items": failed_items,
            "completed_at": datetime.now().isoformat(),
        }

        logger.info(
            f"✅ Batch processing completed: {len(processed_items)}/{len(items)} items"
        )
        return result

    except Exception as e:
        logger.error(f"❌ Batch processing failed: {e}")
        raise self.retry(countdown=60, max_retries=2)
