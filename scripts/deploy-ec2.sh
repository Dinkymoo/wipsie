#!/bin/bash
# Wipsie Ultra-Budget EC2 Deployment Script
# Deploys frontend to S3 and backend to free-tier EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="wipsie"
AWS_REGION="us-east-1"
S3_BUCKET="${PROJECT_NAME}-frontend-$(date +%s)"
INSTANCE_TYPE="t3.micro"  # Free tier eligible

print_header() {
    echo -e "${PURPLE}=====================================
🏦 WIPSIE ULTRA-BUDGET DEPLOYMENT
=====================================${NC}"
}

print_section() {
    echo -e "${BLUE}📋 $1${NC}"
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

# Deploy frontend to S3 (same as budget version)
deploy_frontend() {
    print_section "Deploying Frontend to S3"
    
    cd frontend/wipsie-app
    npm ci
    npm run build:prod
    
    # Create S3 bucket
    aws s3 mb s3://$S3_BUCKET --region $AWS_REGION
    aws s3 website s3://$S3_BUCKET --index-document index.html --error-document index.html
    
    # Set public read policy
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$S3_BUCKET/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file://bucket-policy.json
    rm bucket-policy.json
    
    aws s3 sync dist/wipsie-app/ s3://$S3_BUCKET --delete
    cd ../..
    
    print_success "Frontend deployed to S3"
}

# Create EC2 instance
create_ec2_instance() {
    print_section "Creating EC2 Instance (t3.micro - Free Tier)"
    
    # Create security group
    SG_ID=$(aws ec2 create-security-group \
        --group-name "${PROJECT_NAME}-sg" \
        --description "Security group for Wipsie backend" \
        --query 'GroupId' --output text)
    
    # Allow HTTP and SSH
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 8000 \
        --cidr 0.0.0.0/0
    
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    
    # Get latest Amazon Linux 2 AMI
    AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text)
    
    # Launch instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --count 1 \
        --instance-type $INSTANCE_TYPE \
        --security-group-ids $SG_ID \
        --user-data file://user-data.sh \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT_NAME}-backend}]" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    print_success "EC2 instance created: $INSTANCE_ID"
    print_warning "Waiting for instance to start..."
    
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    print_success "Instance running at: $PUBLIC_IP"
    echo "INSTANCE_ID=$INSTANCE_ID" > deployment-info.txt
    echo "PUBLIC_IP=$PUBLIC_IP" >> deployment-info.txt
    echo "S3_BUCKET=$S3_BUCKET" >> deployment-info.txt
}

# Create user data script for EC2
create_user_data() {
    cat > user-data.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y python3 python3-pip git

# Install PostgreSQL client
amazon-linux-extras install postgresql13

# Clone repository (you'll need to update this with your repo)
cd /home/ec2-user
git clone https://github.com/YOUR_USERNAME/wipsie.git
chown -R ec2-user:ec2-user wipsie

# Install Python dependencies
cd wipsie/backend
pip3 install -r requirements.txt

# Create systemd service
cat > /etc/systemd/system/wipsie-backend.service << 'EOL'
[Unit]
Description=Wipsie Backend API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/wipsie/backend
Environment=DATABASE_URL=postgresql://postgres:WipsieAurora2024!@wipsie-learning-aurora.cluster-xxx.us-east-1.rds.amazonaws.com:5432/wipsie
Environment=CORS_ORIGINS=*
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Start service
systemctl enable wipsie-backend
systemctl start wipsie-backend
EOF
}

# Show deployment instructions
show_deployment_info() {
    print_section "Deployment Complete - Manual Steps Required"
    
    source deployment-info.txt
    
    echo ""
    echo -e "${GREEN}🎉 Ultra-Budget Deployment Created!${NC}"
    echo ""
    echo -e "${BLUE}📋 Your Resources:${NC}"
    echo -e "   🌐 Frontend: http://$S3_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
    echo -e "   🖥️  EC2 Backend: http://$PUBLIC_IP:8000"
    echo -e "   📊 Instance ID: $INSTANCE_ID"
    echo ""
    echo -e "${YELLOW}📝 Manual Setup Required:${NC}"
    echo ""
    echo -e "${BLUE}1. Update Repository URL:${NC}"
    echo "   • Edit user-data.sh with your GitHub repository URL"
    echo "   • Terminate and recreate instance, or manually setup on existing instance"
    echo ""
    echo -e "${BLUE}2. Connect to EC2 Instance:${NC}"
    echo "   ssh -i your-key.pem ec2-user@$PUBLIC_IP"
    echo ""
    echo -e "${BLUE}3. Manual Backend Setup:${NC}"
    echo "   git clone YOUR_REPOSITORY"
    echo "   cd backend"
    echo "   pip3 install -r requirements.txt"
    echo "   export DATABASE_URL='postgresql://postgres:WipsieAurora2024!@wipsie-learning-aurora.cluster-xxx.us-east-1.rds.amazonaws.com:5432/wipsie'"
    echo "   uvicorn main:app --host 0.0.0.0 --port 8000"
    echo ""
    echo -e "${BLUE}4. Update Frontend API URL:${NC}"
    echo "   • Edit src/environments/environment.prod.ts"
    echo "   • Set apiUrl: 'http://$PUBLIC_IP:8000/api/v1'"
    echo "   • Rebuild and redeploy to S3"
    echo ""
    echo -e "${BLUE}💰 Monthly Cost Estimate:${NC}"
    echo -e "   💾 Aurora Serverless v2: $15-25"
    echo -e "   🖥️  EC2 t3.micro: $0-8 (free tier eligible)"
    echo -e "   🌐 S3: $1-3"
    echo -e "   📊 Total: ~$16-36/month"
    echo ""
    echo -e "${RED}⚠️  Security Note:${NC}"
    echo -e "   • Instance allows HTTP from anywhere (0.0.0.0/0)"
    echo -e "   • Consider restricting to your IP for production"
    echo -e "   • Database password is in environment variables"
}

# Main function
main() {
    print_header
    
    echo "🎯 This ultra-budget deployment creates:"
    echo "   • Frontend: S3 static hosting"
    echo "   • Backend: Single EC2 t3.micro instance (free tier)"
    echo "   • Database: Existing Aurora cluster"
    echo ""
    echo "💰 Cost: ~$16-36/month (cheapest option)"
    echo "⚠️  Requires manual setup steps"
    echo ""
    
    read -p "🚀 Continue with ultra-budget deployment? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    create_user_data
    deploy_frontend
    create_ec2_instance
    show_deployment_info
    
    echo ""
    echo -e "${GREEN}🚀 Ultra-budget deployment infrastructure created!${NC}"
    echo -e "${YELLOW}📋 Follow the manual setup steps above to complete deployment${NC}"
}

main "$@"
