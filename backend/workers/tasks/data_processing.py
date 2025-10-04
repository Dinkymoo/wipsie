"""
Data Processing Tasks
Handle data polling, collection, and analysis
"""

import json
import logging
from datetime import datetime

from ..celery_app import app

logger = logging.getLogger(__name__)


@app.task(bind=True)
def process_default_message(self, message_data):
    """Process messages from the default queue"""
    logger.info(f"📨 Processing default message: {self.request.id}")

    try:
        # Parse the message if it's a string
        if isinstance(message_data, str):
            data = json.loads(message_data)
        else:
            data = message_data

        logger.info(
            f"📝 Message content: {data.get('message', 'No message field')}")
        logger.info(f"🆔 Task ID: {data.get('task_id', 'No task ID')}")
        logger.info(f"🔖 Task Type: {data.get('task_type', 'Unknown')}")

        # Simulate processing
        result = {
            'status': 'processed',
            'message_id': self.request.id,
            'processed_at': datetime.now().isoformat(),
            'original_data': data
        }

        logger.info(f"✅ Successfully processed message: {self.request.id}")
        return result

    except Exception as e:
        logger.error(f"❌ Error processing message {self.request.id}: {e}")
        raise self.retry(countdown=60, max_retries=3)


@app.task(bind=True)
def process_data_polling(self, polling_data):
    """Process data polling tasks"""
    logger.info(f"🔍 Processing data polling task: {self.request.id}")

    try:
        # Simulate data polling
        source = polling_data.get('source', 'unknown')
        logger.info(f"📊 Polling data from source: {source}")

        # Mock data collection
        collected_data = {
            'timestamp': datetime.now().isoformat(),
            'source': source,
            'records_collected': 42,  # Mock number
            'status': 'success'
        }

        logger.info(f"✅ Data polling completed: {collected_data}")
        return collected_data

    except Exception as e:
        logger.error(f"❌ Data polling failed: {e}")
        raise self.retry(countdown=120, max_retries=2)


@app.task(bind=True)
def enrich_data(self, raw_data):
    """Enrich raw data with additional information (Data Enricher)"""
    logger.info(f"🔧 Enriching data: {self.request.id}")

    try:
        # Extract basic information
        data_id = raw_data.get('id', 'unknown')
        data_type = raw_data.get('type', 'generic')

        # Enrich with metadata
        enriched_data = {
            **raw_data,
            'enriched_at': datetime.now().isoformat(),
            'enrichment_version': '1.0',
            'metadata': {
                'processing_id': self.request.id,
                'source_validation': 'passed',
                'quality_score': 0.95,
                'tags': [data_type, 'processed', 'enriched']
            }
        }

        # Add type-specific enrichments
        if data_type == 'user_data':
            enriched_data['metadata']['privacy_level'] = 'standard'
            enriched_data['metadata']['retention_days'] = 365
        elif data_type == 'analytics':
            enriched_data['metadata']['aggregation_level'] = 'daily'
            enriched_data['metadata']['dashboard_ready'] = True

        logger.info(f"✅ Data enrichment completed for: {data_id}")
        return enriched_data

    except Exception as e:
        logger.error(f"❌ Data enrichment failed: {e}")
        raise self.retry(countdown=90, max_retries=3)
