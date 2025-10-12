#!/bin/bash

# 🔐 AWS User Setup for Wipsie Infrastructure
# This script helps create a new AWS IAM user with full permissions for Aurora and infrastructure management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  🔐 AWS USER SETUP FOR WIPSIE                ║${NC}"
echo -e "${BLUE}║              Create Full-Permission Infrastructure User       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"

# Function to check current AWS identity
check_current_identity() {
    echo -e "\n${YELLOW}🔍 Current AWS Identity:${NC}"
    if aws sts get-caller-identity 2>/dev/null; then
        echo -e "${GREEN}✅ AWS CLI is configured${NC}"
        
        # Check if current user has IAM permissions
        echo -e "\n${YELLOW}🔍 Testing IAM Permissions:${NC}"
        if aws iam get-user 2>/dev/null >/dev/null; then
            echo -e "${GREEN}✅ Current user has IAM permissions${NC}"
            return 0
        else
            echo -e "${RED}❌ Current user lacks IAM permissions${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ AWS CLI not configured or no credentials${NC}"
        return 1
    fi
}

# Function to create IAM policy document
create_policy_document() {
    echo -e "\n${YELLOW}📄 Creating comprehensive IAM policy...${NC}"
    
    cat > /tmp/wipsie-full-access-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "RDSFullAccess",
            "Effect": "Allow",
            "Action": [
                "rds:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EC2VPCFullAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMFullAccess",
            "Effect": "Allow",
            "Action": [
                "iam:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchFullAccess",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ECSFullAccess",
            "Effect": "Allow",
            "Action": [
                "ecs:*",
                "ecr:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3FullAccess",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SQSFullAccess",
            "Effect": "Allow",
            "Action": [
                "sqs:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "LambdaFullAccess",
            "Effect": "Allow",
            "Action": [
                "lambda:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudFormationAccess",
            "Effect": "Allow",
            "Action": [
                "cloudformation:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EventsAccess",
            "Effect": "Allow",
            "Action": [
                "events:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ElastiCacheAccess",
            "Effect": "Allow",
            "Action": [
                "elasticache:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudFrontAccess",
            "Effect": "Allow",
            "Action": [
                "cloudfront:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SecretsManagerAccess",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ApplicationAutoScalingAccess",
            "Effect": "Allow",
            "Action": [
                "application-autoscaling:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ServiceDiscoveryAccess",
            "Effect": "Allow",
            "Action": [
                "servicediscovery:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    echo -e "${GREEN}✅ Policy document created at /tmp/wipsie-full-access-policy.json${NC}"
}

# Function to create user and policy via AWS CLI
create_user_aws_cli() {
    local username="$1"
    
    echo -e "\n${YELLOW}👤 Creating IAM user: $username${NC}"
    
    # Create the user
    if aws iam create-user --user-name "$username" --path "/wipsie/" 2>/dev/null; then
        echo -e "${GREEN}✅ User $username created successfully${NC}"
    else
        echo -e "${YELLOW}⚠️ User $username may already exist, continuing...${NC}"
    fi
    
    # Create the policy
    local policy_name="WipsieFullAccess"
    echo -e "\n${YELLOW}📋 Creating IAM policy: $policy_name${NC}"
    
    local policy_arn
    policy_arn=$(aws iam create-policy \
        --policy-name "$policy_name" \
        --policy-document file:///tmp/wipsie-full-access-policy.json \
        --description "Full access policy for Wipsie infrastructure management" \
        --query 'Policy.Arn' --output text 2>/dev/null || true)
    
    if [ -z "$policy_arn" ]; then
        # Policy might already exist, try to get ARN
        policy_arn=$(aws iam list-policies --query "Policies[?PolicyName=='$policy_name'].Arn" --output text)
        if [ -n "$policy_arn" ]; then
            echo -e "${YELLOW}⚠️ Policy $policy_name already exists, using existing one${NC}"
        else
            echo -e "${RED}❌ Failed to create or find policy${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ Policy $policy_name created successfully${NC}"
    fi
    
    # Attach policy to user
    echo -e "\n${YELLOW}🔗 Attaching policy to user...${NC}"
    if aws iam attach-user-policy --user-name "$username" --policy-arn "$policy_arn"; then
        echo -e "${GREEN}✅ Policy attached to user successfully${NC}"
    else
        echo -e "${RED}❌ Failed to attach policy to user${NC}"
        return 1
    fi
    
    # Create access key
    echo -e "\n${YELLOW}🔑 Creating access key for user...${NC}"
    local access_key_output
    access_key_output=$(aws iam create-access-key --user-name "$username" --output json)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Access key created successfully${NC}"
        
        # Extract credentials
        local access_key_id
        local secret_access_key
        access_key_id=$(echo "$access_key_output" | jq -r '.AccessKey.AccessKeyId')
        secret_access_key=$(echo "$access_key_output" | jq -r '.AccessKey.SecretAccessKey')
        
        # Save credentials to file
        cat > /tmp/wipsie-aws-credentials.txt << EOF
AWS_ACCESS_KEY_ID=$access_key_id
AWS_SECRET_ACCESS_KEY=$secret_access_key
AWS_DEFAULT_REGION=us-east-1

# To configure AWS CLI with these credentials:
aws configure set aws_access_key_id $access_key_id
aws configure set aws_secret_access_key $secret_access_key
aws configure set default.region us-east-1

# Or export as environment variables:
export AWS_ACCESS_KEY_ID=$access_key_id
export AWS_SECRET_ACCESS_KEY=$secret_access_key
export AWS_DEFAULT_REGION=us-east-1
EOF
        
        echo -e "\n${GREEN}🎉 User setup complete!${NC}"
        echo -e "${BLUE}📄 Credentials saved to: /tmp/wipsie-aws-credentials.txt${NC}"
        echo -e "${YELLOW}⚠️  IMPORTANT: Save these credentials securely and delete the temp file!${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Failed to create access key${NC}"
        return 1
    fi
}

# Function to show manual setup instructions
show_manual_instructions() {
    echo -e "\n${PURPLE}📋 Manual AWS Console Setup Instructions${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
    
    cat << 'EOF'

🔗 AWS Console Setup Steps:

1. 👤 Create IAM User:
   • Go to AWS Console → IAM → Users
   • Click "Create user"
   • Username: wipsie-infrastructure-user
   • Enable "Provide user access to the AWS Management Console" (optional)
   • Click "Next"

2. 🔐 Attach Permissions:
   • Choose "Attach policies directly"
   • Search and select these AWS managed policies:
     ✓ AmazonRDSFullAccess
     ✓ AmazonVPCFullAccess
     ✓ IAMFullAccess
     ✓ CloudWatchFullAccess
     ✓ AmazonECS_FullAccess
     ✓ AmazonS3FullAccess
     ✓ AmazonSQSFullAccess
     ✓ AWSLambda_FullAccess
     ✓ CloudFrontFullAccess
     ✓ SecretsManagerReadWrite
     ✓ ApplicationAutoScalingFullAccess
   • Click "Next" → "Create user"

3. 🔑 Create Access Key:
   • Click on the created user
   • Go to "Security credentials" tab
   • Click "Create access key"
   • Choose "Command Line Interface (CLI)"
   • Check "I understand..." → "Next"
   • Add description: "Wipsie Infrastructure Management"
   • Click "Create access key"
   • SAVE the Access Key ID and Secret Access Key!

4. ⚙️ Configure AWS CLI:
   aws configure set aws_access_key_id YOUR_ACCESS_KEY_ID
   aws configure set aws_secret_access_key YOUR_SECRET_ACCESS_KEY
   aws configure set default.region us-east-1

5. ✅ Test Configuration:
   aws sts get-caller-identity
   aws rds describe-db-instances --max-items 1

EOF
}

# Function to configure AWS CLI with new credentials
configure_aws_cli() {
    echo -e "\n${YELLOW}⚙️ Configure AWS CLI with new credentials${NC}"
    
    if [ -f "/tmp/wipsie-aws-credentials.txt" ]; then
        echo -e "${BLUE}🔧 Found saved credentials, configuring AWS CLI...${NC}"
        source /tmp/wipsie-aws-credentials.txt
        
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
        aws configure set default.region "$AWS_DEFAULT_REGION"
        
        echo -e "${GREEN}✅ AWS CLI configured with new credentials${NC}"
        
        # Test the configuration
        echo -e "\n${YELLOW}🧪 Testing new configuration...${NC}"
        if aws sts get-caller-identity; then
            echo -e "${GREEN}✅ New AWS configuration working!${NC}"
            return 0
        else
            echo -e "${RED}❌ New configuration test failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}📝 Please enter your new AWS credentials:${NC}"
        read -p "Access Key ID: " access_key_id
        read -s -p "Secret Access Key: " secret_access_key
        echo ""
        read -p "Default Region [us-east-1]: " region
        region=${region:-us-east-1}
        
        aws configure set aws_access_key_id "$access_key_id"
        aws configure set aws_secret_access_key "$secret_access_key"
        aws configure set default.region "$region"
        
        echo -e "${GREEN}✅ AWS CLI configured${NC}"
        
        # Test the configuration
        echo -e "\n${YELLOW}🧪 Testing configuration...${NC}"
        if aws sts get-caller-identity; then
            echo -e "${GREEN}✅ AWS configuration working!${NC}"
            return 0
        else
            echo -e "${RED}❌ Configuration test failed${NC}"
            return 1
        fi
    fi
}

# Function to cleanup sensitive files
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up temporary files...${NC}"
    rm -f /tmp/wipsie-full-access-policy.json
    
    read -p "Delete saved credentials file? (y/N): " delete_creds
    if [[ "$delete_creds" =~ ^[Yy]$ ]]; then
        rm -f /tmp/wipsie-aws-credentials.txt
        echo -e "${GREEN}✅ Credentials file deleted${NC}"
    else
        echo -e "${YELLOW}⚠️ Credentials file kept at /tmp/wipsie-aws-credentials.txt${NC}"
        echo -e "${YELLOW}   Please delete it manually after saving credentials securely!${NC}"
    fi
}

# Main menu
show_menu() {
    echo -e "\n${YELLOW}🛠️ AWS User Setup Options:${NC}"
    echo ""
    echo "1. 🔍 Check Current AWS Identity & Permissions"
    echo "2. 👤 Create New IAM User (via AWS CLI)"
    echo "3. 📋 Show Manual Setup Instructions"
    echo "4. ⚙️ Configure AWS CLI with New Credentials"
    echo "5. 🧪 Test Current AWS Configuration"
    echo "6. 🧹 Cleanup Temporary Files"
    echo "7. ❌ Exit"
    echo ""
}

# Main execution
main() {
    # Check dependencies
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠️ jq not installed, installing...${NC}"
        apt update && apt install -y jq
    fi
    
    while true; do
        show_menu
        read -p "Choose an option (1-7): " choice
        
        case $choice in
            1) 
                check_current_identity
                ;;
            2) 
                if check_current_identity; then
                    create_policy_document
                    read -p "Enter username for new IAM user [wipsie-infrastructure-user]: " username
                    username=${username:-wipsie-infrastructure-user}
                    create_user_aws_cli "$username"
                else
                    echo -e "${RED}❌ Cannot create user - current credentials lack IAM permissions${NC}"
                    echo -e "${YELLOW}💡 Use option 3 for manual setup instructions${NC}"
                fi
                ;;
            3) 
                show_manual_instructions
                ;;
            4) 
                configure_aws_cli
                ;;
            5) 
                echo -e "\n${YELLOW}🧪 Testing Current AWS Configuration:${NC}"
                aws sts get-caller-identity
                ;;
            6) 
                cleanup
                ;;
            7) 
                echo -e "${GREEN}👋 Setup complete!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}❌ Invalid option. Please choose 1-7.${NC}"
                ;;
        esac
        
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Run main function
main "$@"
