#!/usr/bin/env python3
"""
Quick Learning Cost Test
"""

# Test the learning profile
print("🎓 LEARNING PROFILE COST BREAKDOWN")
print("=" * 50)

# AWS Free Tier Benefits for Learning
free_tier_services = {
    "AWS Lambda": {
        "monthly_limit": "1M requests + 400K GB-seconds",
        "learning_usage": "5K requests",
        "cost": "$0.00",
        "savings": "~$2/month"
    },
    "Amazon S3": {
        "monthly_limit": "5GB storage + 20K requests",
        "learning_usage": "2GB + 500 requests",
        "cost": "$0.00",
        "savings": "~$1/month"
    },
    "Amazon RDS": {
        "monthly_limit": "750 hours t3.micro + 20GB",
        "learning_usage": "300 hours + 15GB",
        "cost": "$0.00",
        "savings": "~$15/month"
    },
    "Amazon SQS": {
        "monthly_limit": "1M requests",
        "learning_usage": "10K requests",
        "cost": "$0.00",
        "savings": "~$0.50/month"
    },
    "Amazon SES": {
        "monthly_limit": "62K emails (from EC2)",
        "learning_usage": "100 emails",
        "cost": "$0.00",
        "savings": "~$0.10/month"
    },
    "CloudFront": {
        "monthly_limit": "1TB transfer + 10M requests",
        "learning_usage": "2GB + 1K requests",
        "cost": "$0.00",
        "savings": "~$2/month"
    },
    "GitHub Actions": {
        "monthly_limit": "Unlimited (public repos)",
        "learning_usage": "Public repo workflows",
        "cost": "$0.00",
        "savings": "~$5/month"
    }
}

total_savings = 0
for service, details in free_tier_services.items():
    print(f"✅ {service}")
    print(f"   Free Tier: {details['monthly_limit']}")
    print(f"   Your Usage: {details['learning_usage']}")
    print(f"   Cost: {details['cost']}")
    print(f"   You Save: {details['savings']}")
    print()

    # Extract savings amount
    savings_amount = float(details['savings'].replace(
        '~$', '').replace('/month', ''))
    total_savings += savings_amount

print("=" * 50)
print(f"💰 TOTAL MONTHLY COST: $0.00")
print(f"💡 TOTAL SAVINGS vs Production: ~${total_savings:.2f}/month")
print(f"📅 ANNUAL SAVINGS: ~${total_savings * 12:.2f}")
print("=" * 50)

print("\n🎯 LEARNING OPTIMIZATION TIPS:")
print("• Use AWS Free Tier (new accounts get 12 months)")
print("• Keep RDS stopped when not coding (save instance hours)")
print("• Make GitHub repo public (unlimited Actions)")
print("• Use minimal test data sets")
print("• Set billing alerts at $1, $5, $10")
print("• Clean up resources after each session")

print("\n📚 LEARNING PROGRESSION:")
learning_phases = [
    ("Phase 1: Setup & Basics", "$0/month", "Learn AWS fundamentals"),
    ("Phase 2: Real Testing", "$3-5/month", "After free tier expires"),
    ("Phase 3: Portfolio Project", "$10-15/month", "Showcase-ready app"),
    ("Phase 4: Production Skills", "$30+/month", "Enterprise patterns")
]

for phase, cost, description in learning_phases:
    print(f"   📈 {phase:<25} {cost:<15} {description}")

print(f"\n🎉 START WITH $0/MONTH - PERFECT FOR LEARNING!")
