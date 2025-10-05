# 🔒 Terraform Security Guidelines

## Security Checklist

### ✅ Access Control
- [ ] Use IAM roles instead of access keys when possible
- [ ] Apply principle of least privilege
- [ ] Enable MFA for sensitive operations
- [ ] Rotate credentials regularly

### ✅ State Security
- [ ] Store state in encrypted S3 bucket
- [ ] Enable state locking with DynamoDB
- [ ] Restrict access to state files
- [ ] Use separate state files per environment

### ✅ Resource Security
- [ ] Enable encryption at rest for all data stores
- [ ] Use private subnets for databases
- [ ] Configure security groups with minimal required access
- [ ] Enable VPC Flow Logs
- [ ] Use AWS Secrets Manager for sensitive data

### ✅ Code Security
- [ ] No hardcoded credentials in .tf files
- [ ] Use sensitive = true for outputs containing secrets
- [ ] Scan Terraform code with security tools
- [ ] Pin provider versions

## Secure Configuration Examples

### Encrypted RDS Instance
```hcl
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"
  
  # Security configurations
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds.arn
  
  # Network security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Access control
  publicly_accessible = false
  
  # Backup and monitoring
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  monitoring_interval    = 60
  
  # Deletion protection
  deletion_protection = var.environment == "production"
  skip_final_snapshot = var.environment != "production"
}
```

### Secure S3 Bucket
```hcl
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Security Group Best Practices
```hcl
resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  vpc_id      = aws_vpc.main.id

  # Inbound rules - be specific
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from ALB"
  }

  # Outbound rules - be restrictive
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    Environment = var.environment
  }
}
```

## Secret Management

### Using AWS Secrets Manager
```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-${var.environment}-db-password"
  description             = "Database password for ${var.environment}"
  recovery_window_in_days = var.environment == "production" ? 30 : 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
}
```

### Environment Variables (Staging Only)
```bash
# For staging environment - not recommended for production
export TF_VAR_db_password="staging-password-123"
```

## State File Security

### S3 Backend Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "wipsie/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

### State Bucket Security
```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

## Network Security

### VPC Security Best Practices
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

# Private subnets for databases
resource "aws_subnet" "database" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.main.id

  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-${count.index + 1}"
    Environment = var.environment
    Type        = "Database"
  }
}
```

## Monitoring and Alerting

### CloudTrail for Audit Logging
```hcl
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.app_data.arn}/*"]
    }
  }

  tags = {
    Environment = var.environment
  }
}
```

## Compliance

### Tag Strategy
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
    CostCenter  = "Engineering"
  }
}

resource "aws_instance" "example" {
  # ... configuration ...
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app"
    Type = "Application"
  })
}
```

## Security Scanning

### Tools Integration
- **TFSec**: Static analysis for Terraform
- **Checkov**: Policy-as-code scanning
- **Terrascan**: Compliance scanning
- **AWS Config**: Continuous compliance monitoring

### Example GitHub Actions Security Scan
```yaml
- name: 🔒 Run TFSec Security Scan
  uses: aquasecurity/tfsec-action@v1.0.0
  with:
    working_directory: infrastructure/
    soft_fail: true
```
