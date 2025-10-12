# Wipsie Configuration Files Summary

## Infrastructure Configuration Files

### Core Terraform Files
- **[`main.tf`](../infrastructure/main.tf)** - Main infrastructure definition with conditional resources
- **[`variables.tf`](../infrastructure/variables.tf)** - Cost optimization variables and configuration options
- **[`outputs.tf`](../infrastructure/outputs.tf)** - Infrastructure outputs with conditional handling

### Cost Optimization Configurations
- **[`ultra-budget.tfvars`](../infrastructure/ultra-budget.tfvars)** - Maximum cost savings (~$13-18/month)

### Example Usage Configurations
```bash
# Create additional .tfvars files for different scenarios:

# Database learning only
cat > database-learning.tfvars << EOF
enable_nat_gateway = false
enable_rds = true
enable_redis = false  
enable_alb = false
enable_cloudfront = false
EOF

# Web application learning
cat > webapp-learning.tfvars << EOF
enable_nat_gateway = false
enable_rds = true
enable_redis = true
enable_alb = true
enable_cloudfront = false
EOF

# Full production learning  
cat > production-learning.tfvars << EOF
enable_nat_gateway = true
enable_rds = true
enable_redis = true
enable_alb = true
enable_cloudfront = true
EOF
```

## Documentation Files

### Primary Documentation
- **[`COST_OPTIMIZATION_COMPLETE.md`](./COST_OPTIMIZATION_COMPLETE.md)** - Complete cost optimization documentation
- **[`COST_OPTIMIZATION_QUICK_REFERENCE.md`](./COST_OPTIMIZATION_QUICK_REFERENCE.md)** - Quick commands and summary

### Supporting Documentation
- **[`NAT_GATEWAY_COST_OPTIMIZATION.md`](./NAT_GATEWAY_COST_OPTIMIZATION.md)** - NAT Gateway specific changes
- **[`EXTREME_COST_OPTIMIZATION.md`](./EXTREME_COST_OPTIMIZATION.md)** - Detailed cost analysis
- **[`IAM_PERMISSIONS_REQUEST.md`](./IAM_PERMISSIONS_REQUEST.md)** - Required AWS permissions
- **[`ADMIN_IMPLEMENTATION_COMMANDS.md`](./ADMIN_IMPLEMENTATION_COMMANDS.md)** - Commands for AWS administrators

### IAM Configuration
- **[`wipsie-iam-policy.json`](./wipsie-iam-policy.json)** - Ready-to-use IAM policy for infrastructure deployment

## Usage Examples

### Apply Specific Configuration
```bash
# Maximum cost savings
terraform apply -var-file=ultra-budget.tfvars

# Database learning scenario  
terraform apply -var-file=database-learning.tfvars

# Web application learning scenario
terraform apply -var-file=webapp-learning.tfvars

# Production learning scenario
terraform apply -var-file=production-learning.tfvars
```

### Override Specific Variables
```bash
# Enable only specific services
terraform apply \
  -var="enable_rds=true" \
  -var="enable_alb=true" \
  -var="enable_redis=false" \
  -var="enable_nat_gateway=false" \
  -var="enable_cloudfront=false"
```

### Check Configuration Status
```bash
# View current variable values
terraform console
> var.enable_nat_gateway
> var.enable_alb
> var.enable_redis

# View active resources
terraform state list | grep -E "(nat_gateway|elasticache|lb\.main|cloudfront)"
```

## Variable Reference

### Cost Optimization Variables
| Variable | Default | Monthly Cost | Purpose |
|----------|---------|--------------|---------|
| `enable_nat_gateway` | `false` | $45 | Private subnet internet access |
| `enable_alb` | `false` | $16 | Application load balancing |
| `enable_redis` | `false` | $12 | Caching layer |
| `enable_rds` | `true` | $13 | PostgreSQL database |
| `enable_cloudfront` | `false` | $1-5 | Content delivery network |

### Core Configuration Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region for resources |
| `environment` | `staging` | Environment name |
| `project_name` | `wipsie` | Project identifier |
| `vpc_cidr` | `10.0.0.0/16` | VPC IP address range |

### Learning Path Configurations

#### Phase 1: Core Learning ($13-18/month)
```hcl
enable_nat_gateway = false
enable_rds = true
enable_redis = false
enable_alb = false  
enable_cloudfront = false
```

#### Phase 2: Database + Load Balancing ($29-34/month)
```hcl
enable_nat_gateway = false
enable_rds = true
enable_redis = false
enable_alb = true
enable_cloudfront = false
```

#### Phase 3: Add Caching ($41-46/month)
```hcl
enable_nat_gateway = false
enable_rds = true
enable_redis = true
enable_alb = true
enable_cloudfront = false
```

#### Phase 4: Full Production ($86-91/month)
```hcl
enable_nat_gateway = true
enable_rds = true
enable_redis = true
enable_alb = true
enable_cloudfront = true
```

## File Maintenance

### Regular Updates
1. **Cost Monitoring**: Review monthly AWS bills and adjust configurations
2. **Security Updates**: Keep IAM policies updated with latest best practices
3. **Version Control**: Commit configuration changes with descriptive messages

### Backup Important Configurations
```bash
# Backup current terraform state
terraform state pull > terraform-state-backup-$(date +%Y%m%d).json

# Export current variable values
terraform output -json > current-outputs-$(date +%Y%m%d).json
```

---
*This summary provides quick access to all configuration files and their purposes for the Wipsie cost-optimized learning environment.*
