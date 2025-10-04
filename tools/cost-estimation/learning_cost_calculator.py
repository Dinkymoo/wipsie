#!/usr/bin/env python3
"""
Learning Environment Cost Calculator
Optimized for educational use with minimal costs
"""


def calculate_learning_costs():
    """Calculate costs optimized for learning environment."""

    print("🎓 Learning Environment Cost Analysis")
    print("=" * 50)
    print("Optimized for: Education, experimentation, portfolio projects")
    print("=" * 50)

    # Free tier and learning optimizations
    free_services = {
        "AWS Lambda": {
            "cost": 0.00,
            "limit": "1M requests/month",
            "learning_note": "Perfect for learning serverless"
        },
        "Amazon S3": {
            "cost": 0.00,
            "limit": "5GB storage + 20K requests",
            "learning_note": "Host your frontend for free"
        },
        "Amazon RDS (Free Tier)": {
            "cost": 0.00,
            "limit": "t3.micro, 20GB, 750 hours/month",
            "learning_note": "12 months free for new accounts"
        },
        "Amazon SQS": {
            "cost": 0.00,
            "limit": "1M requests/month",
            "learning_note": "Learn message queues for free"
        },
        "Amazon SES": {
            "cost": 0.00,
            "limit": "62K emails/month (from EC2)",
            "learning_note": "Email notifications covered"
        },
        "CloudFront": {
            "cost": 0.00,
            "limit": "1TB data transfer + 10M requests",
            "learning_note": "CDN learning included"
        }
    }

    # Paid services (minimal usage)
    minimal_paid = {
        "GitHub Actions": {
            "cost": 0.00,
            "limit": "2000 minutes/month (public repos)",
            "learning_note": "Free for public repositories"
        }
    }

    print("\n🆓 **FREE TIER SERVICES** (Perfect for Learning)")
    print("-" * 50)
    total_free = 0
    for service, details in free_services.items():
        print(f"✅ {service:<25} ${details['cost']:>6.2f}")
        print(f"   📋 {details['limit']}")
        print(f"   💡 {details['learning_note']}")
        print()

    print("\n📚 **LEARNING-SPECIFIC OPTIMIZATIONS**")
    print("-" * 50)

    optimizations = [
        "🎯 Use AWS Free Tier (12 months for new accounts)",
        "🎯 Keep RDS instance stopped when not developing",
        "🎯 Use t3.micro instances (Free Tier eligible)",
        "🎯 Make GitHub repo public (free Actions)",
        "🎯 Use minimal data sets for testing",
        "🎯 Clean up resources after learning sessions"
    ]

    for tip in optimizations:
        print(f"   {tip}")

    print(f"\n💰 **TOTAL MONTHLY COST FOR LEARNING: $0.00**")
    print(f"🎉 **ANNUAL COST: $0.00** (with proper free tier usage)")

    print("\n⚠️  **IMPORTANT LEARNING NOTES:**")
    print("-" * 50)
    print("• AWS Free Tier lasts 12 months from account creation")
    print("• Always stop/delete resources when not in use")
    print("• Set up billing alerts at $1, $5, $10")
    print("• Use AWS Cost Explorer to monitor usage")
    print("• Consider AWS Educate or GitHub Student benefits")

    print("\n🚀 **LEARNING PROGRESSION:**")
    print("-" * 50)
    phases = {
        "Phase 1 - Free Tier": "$0/month - Learn basics",
        "Phase 2 - Small Scale": "$5-15/month - Real-world testing",
        "Phase 3 - Portfolio": "$15-30/month - Showcase projects",
        "Phase 4 - Production Ready": "$50+/month - Job-ready skills"
    }

    for phase, cost in phases.items():
        print(f"   📈 {phase:<20} {cost}")


if __name__ == "__main__":
    calculate_learning_costs()
