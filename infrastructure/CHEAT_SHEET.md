# 📊 Terraform Infrastructure Cheat Sheet

## Quick Commands

### Initialization & Validation
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Check formatting
terraform fmt -check
```

### Planning & Deployment
```bash
# Plan changes (staging)
terraform plan -var-file="staging.tfvars"

# Plan changes (production)
terraform plan -var-file="production.tfvars"

# Apply changes
terraform apply -var-file="staging.tfvars"

# Apply with auto-approve (use with caution)
terraform apply -auto-approve -var-file="staging.tfvars"
```

### State Management
```bash
# Show current state
terraform show

# List resources in state
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0
```

### Outputs & Information
```bash
# Show all outputs
terraform output

# Show specific output
terraform output vpc_id

# Show sensitive outputs
terraform output -json | jq '.rds_endpoint.value'
```

### Destruction
```bash
# Plan destruction
terraform plan -destroy -var-file="staging.tfvars"

# Destroy infrastructure
terraform destroy -var-file="staging.tfvars"

# Destroy specific resource
terraform destroy -target=aws_instance.example
```

## Variable Overrides

### Command Line
```bash
terraform apply -var="environment=staging" -var="rds_instance_class=db.t3.small"
```

### Environment Variables
```bash
export TF_VAR_environment="staging"
export TF_VAR_aws_region="us-west-2"
terraform apply
```

## Debugging

### Enable Detailed Logging
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH="./terraform.log"
terraform apply
```

### Trace API Calls
```bash
export TF_LOG=TRACE
terraform apply 2>&1 | grep -E "(aws|error)"
```

## Security Best Practices

### Sensitive Variables
```bash
# Use environment variables for secrets
export TF_VAR_db_password="$(aws secretsmanager get-secret-value --secret-id prod-db-password --query SecretString --output text)"
```

### Remote State
```bash
# Configure S3 backend
terraform init -backend-config="bucket=my-terraform-state"
```

## Common Patterns

### Conditional Resources
```hcl
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.public_subnet_cidrs) : 0
  # ... configuration
}
```

### For Each with Maps
```hcl
resource "aws_subnet" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.main.id
  # ... configuration
}
```

## Troubleshooting

### Common Errors
- **State Lock**: `terraform force-unlock <LOCK_ID>`
- **Resource Already Exists**: Use `terraform import`
- **Insufficient Permissions**: Check IAM policies
- **Resource Limits**: Verify AWS service quotas

### Validation Workflow
```bash
terraform validate
terraform fmt -check
terraform plan -detailed-exitcode
terraform apply
