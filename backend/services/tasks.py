from celery import current_task
from backend.core.celery_app import celery_app
from backend.services.lambda_service import LambdaService
import httpx
import asyncio
from datetime import datetime


@celery_app.task(bind=True)
def poll_data(self, source_url: str, data_type: str):
    """
    Celery task to poll data from external sources
    """
    try:
        # Update task state
        self.update_state(state='PROGRESS', meta={
                          'status': 'Starting data polling'})

        # Poll data (this is a simple example)
        response = httpx.get(source_url, timeout=30)
        data = response.json()

        # Process and store data
        processed_data = {
            'type': data_type,
            'data': data,
            'timestamp': datetime.utcnow().isoformat(),
            'source': source_url
        }

        # Here you would typically save to database
        # db_service.save_data_point(processed_data)

        return {
            'status': 'completed',
            'message': f'Successfully polled {data_type} data',
            'data': processed_data
        }

    except Exception as e:
        self.update_state(
            state='FAILURE',
            meta={'status': 'Failed', 'error': str(e)}
        )
        raise


@celery_app.task(bind=True)
def process_task(self, task_id: int, task_data: dict):
    """
    Celery task to process background tasks
    """
    try:
        self.update_state(state='PROGRESS', meta={
                          'status': f'Processing task {task_id}'})

        # Simulate task processing
        task_type = task_data.get('type', 'generic')

        if task_type == 'data_analysis':
            # Simulate data analysis
            result = analyze_data(task_data.get('dataset'))
        elif task_type == 'report_generation':
            # Simulate report generation
            result = generate_report(task_data.get('report_config'))
        else:
            result = {'message': f'Processed {task_type} task'}

        return {
            'status': 'completed',
            'task_id': task_id,
            'result': result
        }

    except Exception as e:
        self.update_state(
            state='FAILURE',
            meta={'status': 'Failed', 'error': str(e)}
        )
        raise


@celery_app.task(bind=True)
def send_notification(self, recipient: str, message: str, notification_type: str = 'email'):
    """
    Celery task to send notifications
    """
    try:
        self.update_state(state='PROGRESS', meta={
                          'status': f'Sending {notification_type} to {recipient}'})

        # Here you would integrate with email service, SMS, etc.
        if notification_type == 'email':
            # send_email(recipient, message)
            pass
        elif notification_type == 'sms':
            # send_sms(recipient, message)
            pass

        return {
            'status': 'completed',
            'message': f'{notification_type} sent to {recipient}'
        }

    except Exception as e:
        self.update_state(
            state='FAILURE',
            meta={'status': 'Failed', 'error': str(e)}
        )
        raise


@celery_app.task
def invoke_lambda_function(function_name: str, payload: dict):
    """
    Celery task to invoke AWS Lambda functions
    """
    try:
        # Use asyncio to run the async lambda service
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(
            LambdaService.invoke_function(function_name, payload)
        )
        loop.close()

        return {
            'status': 'completed',
            'function_name': function_name,
            'result': result
        }

    except Exception as e:
        return {
            'status': 'failed',
            'error': str(e)
        }


def analyze_data(dataset):
    """Simulate data analysis"""
    return {
        'analysis_type': 'statistical_summary',
        'records_processed': len(dataset) if dataset else 0,
        'timestamp': datetime.utcnow().isoformat()
    }


def generate_report(config):
    """Simulate report generation"""
    return {
        'report_name': config.get('name', 'report') + '.pdf',
        'pages': config.get('pages', 10),
        'timestamp': datetime.utcnow().isoformat()
    }
