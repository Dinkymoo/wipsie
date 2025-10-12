#!/bin/bash
# Deploy Wipsie frontend to S3 for learning environment
# This script builds the Angular app and deploys it to S3

set -e

# Configuration
PROJECT_NAME="wipsie"
ENVIRONMENT="staging"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🚀 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Install dependencies
install_dependencies() {
    print_step "Installing frontend dependencies..."
    
    cd /workspaces/wipsie/frontend/wipsie-app
    
    if [ ! -d "node_modules" ]; then
        npm install
    else
        print_success "Dependencies already installed"
    fi
}

# Update environment configuration
update_environment() {
    print_step "Updating environment configuration..."
    
    # Create environment file for production/staging
    cat > src/environments/environment.ts << EOF
export const environment = {
  production: true,
  apiUrl: 'http://localhost:8000',  // Will be updated after backend deployment
  environment: '${ENVIRONMENT}'
};
EOF

    print_success "Environment configuration updated"
}

# Build the application
build_application() {
    print_step "Building Angular application..."
    
    # Build for production
    npm run build --prod
    
    print_success "Application built successfully"
}

# Deploy to S3
deploy_to_s3() {
    print_step "Deploying to S3..."
    
    # Get S3 bucket name from Terraform
    cd /workspaces/wipsie/infrastructure
    S3_BUCKET=$(terraform output -raw s3_frontend_bucket 2>/dev/null)
    
    if [ -z "$S3_BUCKET" ]; then
        print_error "Could not get S3 bucket name from Terraform"
        exit 1
    fi
    
    print_step "Uploading to bucket: ${S3_BUCKET}"
    
    # Upload files to S3
    cd /workspaces/wipsie/frontend/wipsie-app
    aws s3 sync dist/ s3://${S3_BUCKET}/ --delete
    
    # Set up website configuration
    aws s3 website s3://${S3_BUCKET}/ --index-document index.html --error-document error.html
    
    print_success "Deployed to S3: ${S3_BUCKET}"
}

# Create simple learning frontend if Angular app doesn't exist
create_simple_frontend() {
    print_step "Creating simple learning frontend..."
    
    cd /workspaces/wipsie/frontend
    
    # Create a simple HTML frontend for learning
    mkdir -p simple-frontend
    
    cat > simple-frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wipsie Learning App</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        
        h1 {
            color: #667eea;
            text-align: center;
            margin-bottom: 30px;
        }
        
        .status {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
        
        .api-test {
            margin: 20px 0;
        }
        
        .btn {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
        }
        
        .btn:hover {
            background: #5a67d8;
        }
        
        .response {
            background: #e8f5e8;
            border: 1px solid #4caf50;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            font-family: monospace;
            white-space: pre-wrap;
        }
        
        .error {
            background: #fdeaea;
            border: 1px solid #f44336;
            color: #d32f2f;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Wipsie Learning Application</h1>
        
        <div class="status">
            <h3>📊 System Status</h3>
            <p>Frontend: <span id="frontend-status">✅ Running</span></p>
            <p>Backend API: <span id="backend-status">🔄 Testing...</span></p>
        </div>
        
        <div class="api-test">
            <h3>🚀 API Testing</h3>
            <button class="btn" onclick="testHealthCheck()">Test Health Check</button>
            <button class="btn" onclick="testRoot()">Test Root Endpoint</button>
            <button class="btn" onclick="testSQS()">Test SQS Integration</button>
            
            <div id="response-area"></div>
        </div>
        
        <div class="status">
            <h3>💰 Cost Optimization</h3>
            <p>This learning environment runs on Fargate Spot instances</p>
            <p>Estimated cost: <strong>~$0.014/hour when running</strong></p>
            <p>Scale to zero when not learning to save costs!</p>
        </div>
        
        <div class="status">
            <h3>🎮 Learning Features</h3>
            <ul>
                <li>FastAPI Backend with health checks</li>
                <li>PostgreSQL database integration</li>
                <li>SQS message queue processing</li>
                <li>ECS Fargate serverless containers</li>
                <li>Auto-scaling based on demand</li>
            </ul>
        </div>
    </div>

    <script>
        // Configuration - will be updated by deployment script
        const API_BASE_URL = 'http://localhost:8000';
        
        async function makeRequest(endpoint, method = 'GET') {
            const responseArea = document.getElementById('response-area');
            
            try {
                const response = await fetch(`${API_BASE_URL}${endpoint}`, {
                    method: method,
                    headers: {
                        'Content-Type': 'application/json',
                    }
                });
                
                const data = await response.json();
                
                responseArea.innerHTML = `
                    <div class="response">
                        <strong>✅ ${endpoint}</strong><br>
                        Status: ${response.status}<br>
                        Response: ${JSON.stringify(data, null, 2)}
                    </div>
                `;
                
                // Update backend status
                document.getElementById('backend-status').innerHTML = '✅ Connected';
                
            } catch (error) {
                responseArea.innerHTML = `
                    <div class="response error">
                        <strong>❌ ${endpoint}</strong><br>
                        Error: ${error.message}<br>
                        Note: Make sure the backend service is running
                    </div>
                `;
                
                // Update backend status
                document.getElementById('backend-status').innerHTML = '❌ Disconnected';
            }
        }
        
        function testHealthCheck() {
            makeRequest('/health');
        }
        
        function testRoot() {
            makeRequest('/');
        }
        
        function testSQS() {
            makeRequest('/sqs/test', 'POST');
        }
        
        // Test connection on page load
        window.onload = function() {
            testHealthCheck();
        };
    </script>
</body>
</html>
EOF

    print_success "Simple learning frontend created"
}

# Deploy simple frontend to S3
deploy_simple_frontend() {
    print_step "Deploying simple frontend to S3..."
    
    # Get S3 bucket name from Terraform
    cd /workspaces/wipsie/infrastructure
    S3_BUCKET=$(terraform output -raw s3_frontend_bucket 2>/dev/null)
    
    if [ -z "$S3_BUCKET" ]; then
        print_error "Could not get S3 bucket name from Terraform"
        exit 1
    fi
    
    # Upload simple frontend
    cd /workspaces/wipsie/frontend
    aws s3 sync simple-frontend/ s3://${S3_BUCKET}/ --delete
    
    # Make bucket publicly readable for learning purposes
    aws s3api put-bucket-policy --bucket ${S3_BUCKET} --policy '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::'${S3_BUCKET}'/*"
            }
        ]
    }'
    
    # Configure as website
    aws s3 website s3://${S3_BUCKET}/ --index-document index.html
    
    # Get website URL
    WEBSITE_URL="http://${S3_BUCKET}.s3-website-${REGION}.amazonaws.com"
    
    print_success "Frontend deployed to: ${WEBSITE_URL}"
    
    return 0
}

# Show access information
show_access_info() {
    print_step "Access Information:"
    
    cd /workspaces/wipsie/infrastructure
    S3_BUCKET=$(terraform output -raw s3_frontend_bucket 2>/dev/null)
    WEBSITE_URL="http://${S3_BUCKET}.s3-website-${REGION}.amazonaws.com"
    
    echo ""
    echo "🌐 Frontend URL: ${WEBSITE_URL}"
    echo "📱 Mobile-friendly: Yes"
    echo "🔧 API Testing: Built-in"
    echo "💰 Hosting Cost: ~$0.50/month for learning"
    echo ""
    echo "🎮 Features:"
    echo "  • Real-time API testing"
    echo "  • Backend health monitoring"
    echo "  • Cost optimization info"
    echo "  • Learning-focused UI"
}

# Main execution
main() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}🎯 WIPSIE FRONTEND DEPLOYMENT${NC}"
    echo -e "${BLUE}=================================${NC}"
    
    check_prerequisites
    
    # Check if Angular app exists and is buildable
    if [ -f "/workspaces/wipsie/frontend/wipsie-app/package.json" ]; then
        print_step "Angular app detected, attempting to build..."
        install_dependencies
        update_environment
        
        if build_application; then
            deploy_to_s3
        else
            print_warning "Angular build failed, falling back to simple frontend"
            create_simple_frontend
            deploy_simple_frontend
        fi
    else
        print_step "No Angular app found, creating simple learning frontend..."
        create_simple_frontend
        deploy_simple_frontend
    fi
    
    show_access_info
    
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}✅ Frontend Deployment Complete!${NC}"
    echo -e "${GREEN}=================================${NC}"
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
