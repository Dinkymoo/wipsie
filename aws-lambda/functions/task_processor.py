import json
import os
import requests
from datetime import datetime
from typing import Dict, Any


def lambda_handler(event, context):
    """
    Enhanced Task Processor Lambda Function
    Processes background tasks asynchronously with improved error handling
    """
    
    try:
        # Extract task data from the event
        task_data = event.get('task_data', {})
        task_type = task_data.get('type', 'unknown')
        task_id = task_data.get('id', 'unknown')
        
        print(f"Processing task {task_id} of type {task_type}")

        # Process different types of tasks
        if task_type == 'email_notification':
            result = process_email_notification(task_data)
        elif task_type == 'data_analysis':
            result = process_data_analysis(task_data)
        elif task_type == 'report_generation':
            result = process_report_generation(task_data)
        elif task_type == 'data_cleanup':
            result = process_data_cleanup(task_data)
        elif task_type == 'webhook_call':
            result = process_webhook_call(task_data)
        else:
            result = {
                'status': 'error',
                'message': f'Unknown task type: {task_type}',
                'supported_types': ['email_notification', 'data_analysis', 'report_generation', 'data_cleanup', 'webhook_call']
            }

        # Update task status via API if configured
        api_base_url = os.environ.get('API_BASE_URL')
        if api_base_url and task_id != 'unknown':
            update_task_status(api_base_url, task_id, result)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Task processed successfully',
                'task_id': task_id,
                'task_type': task_type,
                'result': result,
                'timestamp': datetime.utcnow().isoformat()
            })
        }

    except Exception as e:
        # Ensure task_data is defined for error handling
        task_data = event.get('task_data', {}) if 'task_data' not in locals() else task_data
        
        error_response = {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to process task',
                'task_id': task_data.get('id', 'unknown'),
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
        print(f"Error processing task: {e}")
        return error_response


def process_email_notification(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process email notification task using AWS SES or SNS"""
    try:
        recipient = task_data.get('recipient', 'unknown')
        subject = task_data.get('subject', 'Notification')
        
        # In a real implementation, you'd use AWS SES
        # ses_client = boto3.client('ses')
        # response = ses_client.send_email(...)
        
        # For now, simulate the email sending
        print(f"Sending email to {recipient}: {subject}")
        
        return {
            'status': 'success',
            'message': f"Email sent to {recipient}",
            'subject': subject,
            'processing_time': 0.5
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'message': f"Failed to send email: {str(e)}"
        }


def process_data_analysis(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process data analysis task"""
    try:
        dataset_id = task_data.get('dataset_id', 'unknown')
        analysis_type = task_data.get('analysis_type', 'basic')
        
        # Simulate data analysis processing
        print(f"Analyzing dataset {dataset_id} with {analysis_type} analysis")
        
        # Mock analysis results
        results = {
            'dataset_id': dataset_id,
            'analysis_type': analysis_type,
            'records_processed': 1000 + hash(dataset_id) % 5000,
            'anomalies_detected': hash(dataset_id) % 10,
            'processing_time': 2.3
        }
        
        return {
            'status': 'success',
            'message': f"Analysis completed for dataset {dataset_id}",
            'results': results
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'message': f"Failed to analyze data: {str(e)}"
        }


def process_report_generation(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process report generation task"""
    try:
        report_name = task_data.get('report_name', 'unknown')
        report_type = task_data.get('report_type', 'summary')
        date_range = task_data.get('date_range', '7d')
        
        print(f"Generating {report_type} report: {report_name} for {date_range}")
        
        # In a real implementation, you'd:
        # 1. Query the database for report data
        # 2. Generate the report (PDF, Excel, etc.)
        # 3. Store it in S3
        # 4. Send notification with download link
        
        # Mock S3 URL
        s3_url = f"https://my-bucket.s3.amazonaws.com/reports/{report_name}_{datetime.now().strftime('%Y%m%d')}.pdf"
        
        return {
            'status': 'success',
            'message': f"Report generated: {report_name}",
            'report_url': s3_url,
            'report_type': report_type,
            'date_range': date_range,
            'processing_time': 5.2
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'message': f"Failed to generate report: {str(e)}"
        }


def process_data_cleanup(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process data cleanup task"""
    try:
        cleanup_type = task_data.get('cleanup_type', 'old_records')
        days_old = task_data.get('days_old', 30)
        
        print(f"Running {cleanup_type} cleanup for records older than {days_old} days")
        
        # Mock cleanup results
        cleaned_records = hash(str(days_old)) % 1000
        
        return {
            'status': 'success',
            'message': f"Cleanup completed: {cleanup_type}",
            'records_cleaned': cleaned_records,
            'days_old': days_old,
            'processing_time': 1.8
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'message': f"Failed to cleanup data: {str(e)}"
        }


def process_webhook_call(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process webhook call task"""
    try:
        webhook_url = task_data.get('webhook_url')
        payload = task_data.get('payload', {})
        method = task_data.get('method', 'POST').upper()
        
        if not webhook_url:
            return {
                'status': 'error',
                'message': 'webhook_url is required'
            }
        
        print(f"Calling webhook: {method} {webhook_url}")
        
        # Make the webhook call
        if method == 'POST':
            response = requests.post(webhook_url, json=payload, timeout=30)
        elif method == 'GET':
            response = requests.get(webhook_url, params=payload, timeout=30)
        else:
            return {
                'status': 'error',
                'message': f'Unsupported HTTP method: {method}'
            }
        
        response.raise_for_status()
        
        return {
            'status': 'success',
            'message': f"Webhook called successfully: {webhook_url}",
            'response_status': response.status_code,
            'response_body': response.text[:500],  # Truncate response
            'processing_time': 0.8
        }
        
    except Exception as e:
        return {
            'status': 'error',
            'message': f"Failed to call webhook: {str(e)}"
        }


def update_task_status(api_base_url: str, task_id: str, result: Dict[str, Any]) -> None:
    """Update task status via the FastAPI backend"""
    try:
        # In a real implementation, you'd call your API to update task status
        print(f"Updating task {task_id} status via API: {api_base_url}")
        
        # This would be something like:
        # requests.put(f"{api_base_url}/api/tasks/{task_id}", json={
        #     'status': 'completed' if result['status'] == 'success' else 'failed',
        #     'result': result
        # })
        
    except Exception as e:
        print(f"Failed to update task status: {e}")
