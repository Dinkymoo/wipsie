# 🔧 Lambda Function Troubleshooting Guide

## Step 1: Test Basic Lambda Function

First, let's verify the Lambda function can execute at all:

```bash
# Check if the test function is working
curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/

# If still getting 500 errors, check logs
aws logs describe-log-streams \
  --log-group-name /aws/lambda/wipsie-backend \
  --region eu-west-1 \
  --order-by LastEventTime \
  --descending \
  --max-items 1
```

## Step 2: Manual Lambda Testing in AWS Console

1. **Go to AWS Console** → Lambda → Functions → `wipsie-backend`
2. **Test tab** → Create test event:
   - Template: "API Gateway AWS Proxy"
   - Event name: "test-event"
   - Use this test payload:

```json
{
  "httpMethod": "GET",
  "path": "/",
  "headers": {
    "Accept": "application/json"
  },
  "queryStringParameters": null,
  "body": null,
  "isBase64Encoded": false,
  "requestContext": {
    "requestId": "test-request"
  }
}
```

3. **Click Test** and check the response

## Step 3: Check CloudWatch Logs

```bash
# Get the latest log stream
LATEST_STREAM=$(aws logs describe-log-streams \
  --log-group-name /aws/lambda/wipsie-backend \
  --region eu-west-1 \
  --order-by LastEventTime \
  --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

# Get recent log events
aws logs get-log-events \
  --log-group-name /aws/lambda/wipsie-backend \
  --log-stream-name "$LATEST_STREAM" \
  --region eu-west-1 \
  --start-time $(date -d '10 minutes ago' +%s)000
```

## Step 4: Verify Lambda Configuration

```bash
# Check current Lambda configuration
aws lambda get-function-configuration \
  --function-name wipsie-backend \
  --region eu-west-1

# Key things to verify:
# - Handler: should be "test_lambda.lambda_handler" 
# - Runtime: python3.11
# - Timeout: 30 seconds
# - Memory: 512 MB
```

## Step 5: Test API Gateway Integration

```bash
# Test with verbose output to see headers
curl -v https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/

# Test different paths
curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/test
curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/health
```

## Step 6: Check API Gateway Logs

1. **AWS Console** → API Gateway → `wipsie-api` 
2. **Stages** → `prod` → **Logs/Tracing** tab
3. Enable **CloudWatch Logs** and **Access Logging**
4. Check for integration errors

## Step 7: Verify Lambda Permissions

```bash
# Check if API Gateway has permission to invoke Lambda
aws lambda get-policy \
  --function-name wipsie-backend \
  --region eu-west-1
```

## Step 8: Common Fixes

### Fix 1: Reset Lambda Handler
```bash
aws lambda update-function-configuration \
  --function-name wipsie-backend \
  --handler test_lambda.lambda_handler \
  --region eu-west-1
```

### Fix 2: Add Missing Lambda Permission
```bash
aws lambda add-permission \
  --function-name wipsie-backend \
  --statement-id allow-api-gateway \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:eu-west-1:$(aws sts get-caller-identity --query Account --output text):yb6i0oap3c/*/*" \
  --region eu-west-1
```

### Fix 3: Recreate API Gateway Integration
```bash
# Delete and recreate the integration
aws apigateway delete-integration \
  --rest-api-id yb6i0oap3c \
  --resource-id [RESOURCE_ID] \
  --http-method ANY \
  --region eu-west-1

# Get root resource ID first
aws apigateway get-resources \
  --rest-api-id yb6i0oap3c \
  --region eu-west-1
```

## Step 9: Deploy Working FastAPI Version

Once basic Lambda is working, redeploy with FastAPI:

```bash
# Reset to original handler and redeploy backend
aws lambda update-function-configuration \
  --function-name wipsie-backend \
  --handler lambda_handler.lambda_handler \
  --region eu-west-1

# Redeploy backend with proper dependencies
bash scripts/deploy-backend-only.sh
```

## Step 10: Test Full Application

```bash
# Test FastAPI endpoints
curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/
curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/docs
curl https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/api/v1/health
```

## 🔍 Most Likely Issues

1. **Lambda Handler**: Incorrect handler path
2. **Permissions**: API Gateway can't invoke Lambda
3. **Dependencies**: Missing pydantic-core or other packages
4. **Integration**: API Gateway-Lambda proxy integration not working
5. **Timeout**: Lambda function timing out

## 🎯 Quick Win Strategy

1. Start with Step 2 (AWS Console test) - this will tell you if Lambda works at all
2. If Lambda test fails → check CloudWatch logs (Step 3)
3. If Lambda test works but API Gateway fails → check permissions (Step 7)
4. Use the simple test function to isolate the issue
5. Once basic Lambda works, gradually add complexity back

---

**Most Common Resolution**: The issue is usually either handler configuration or missing Lambda permissions for API Gateway.
