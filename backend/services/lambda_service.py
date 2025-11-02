import asyncio
import json
from concurrent.futures import (
    ThreadPoolExecutor,
)
from typing import (
    Any,
    Dict,
    List,
)

import boto3

from core.config import (
    settings,
)


class LambdaService:
    def __init__(self):
        self.lambda_client = boto3.client(
            "lambda",
            region_name=settings.AWS_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        )

    @classmethod
    async def invoke_function(
        cls, function_name: str, payload: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Invoke an AWS Lambda function asynchronously"""
        service = cls()

        # Run the synchronous boto3 call in a thread pool
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            response = await loop.run_in_executor(
                executor, service._invoke_function_sync, function_name, payload
            )

        return response

    def _invoke_function_sync(
        self, function_name: str, payload: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Synchronous Lambda function invocation"""
        try:
            response = self.lambda_client.invoke(
                FunctionName=function_name,
                InvocationType="RequestResponse",
                Payload=json.dumps(payload),
            )

            response_payload = json.loads(response["Payload"].read())

            return {
                "statusCode": response["StatusCode"],
                "payload": response_payload,
                "function_name": function_name,
            }
        except Exception as e:
            return {
                "statusCode": 500,
                "error": str(e),
                "function_name": function_name,
            }

    @classmethod
    async def list_functions(cls) -> List[Dict[str, Any]]:
        """List all Lambda functions"""
        service = cls()

        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            response = await loop.run_in_executor(
                executor, service._list_functions_sync
            )

        return response

    def _list_functions_sync(self) -> List[Dict[str, Any]]:
        """Synchronous Lambda function listing"""
        try:
            response = self.lambda_client.list_functions()
            functions = []

            for func in response.get("Functions", []):
                functions.append(
                    {
                        "function_name": func["FunctionName"],
                        "runtime": func["Runtime"],
                        "last_modified": func["LastModified"],
                        "description": func.get("Description", ""),
                        "timeout": func["Timeout"],
                        "memory_size": func["MemorySize"],
                    }
                )

            return functions
        except Exception as e:
            return [{"error": str(e)}]

    @classmethod
    async def deploy_function(cls, function_name: str) -> Dict[str, Any]:
        """Deploy a Lambda function (placeholder for actual deployment logic)"""
        # This would typically involve:
        # 1. Packaging the function code
        # 2. Creating/updating the Lambda function
        # 3. Setting up triggers and permissions

        return {
            "status": "success",
            "message": f"Function {function_name} deployment initiated",
            "function_name": function_name,
        }
