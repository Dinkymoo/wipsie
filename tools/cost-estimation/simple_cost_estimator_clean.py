#!/usr/bin/env python3
"""
Simple AWS Cost Estimator for Wipsie Application

Quick cost estimates based on typical usage patterns.
"""

import sys
from typing import Dict


def get_cost_estimates() -> Dict[str, Dict[str, float]]:
    """Get predefined cost estimates for different environments."""
    return {
        "development": {
            "AWS Lambda": 2.00,
            "Amazon S3": 1.00,
            "Amazon RDS": 8.00,
            "Amazon SQS": 0.50,
            "Amazon SES": 0.10,
            "CloudFront": 1.00,
            "GitHub Actions": 2.00,
        },
        "staging": {
            "AWS Lambda": 8.00,
            "Amazon S3": 3.00,
            "Amazon RDS": 25.00,
            "Amazon SQS": 2.00,
            "Amazon SES": 1.00,
            "CloudFront": 5.00,
            "GitHub Actions": 5.00,
        },
        "production": {
            "AWS Lambda": 25.00,
            "Amazon S3": 15.00,
            "Amazon RDS": 120.00,
            "Amazon SQS": 8.00,
            "Amazon SES": 5.00,
            "CloudFront": 20.00,
            "GitHub Actions": 10.00,  # Regular deployments
        }
    }


def print_cost_estimate(environment: str) -> None:
    """Print cost estimate for the specified environment."""
    estimates = get_cost_estimates()

    if environment not in estimates:
        print(f"❌ Unknown environment: {environment}")
        print(f"Available environments: {', '.join(estimates.keys())}")
        return

    costs = estimates[environment]
    total = sum(costs.values())

    print(f"💰 Cost Estimate - {environment.title()} Environment")
    print("=" * 50)

    for service, cost in costs.items():
        percentage = (cost / total) * 100
        print(f"{service:<20} ${cost:>6.2f} ({percentage:4.1f}%)")

    print("-" * 50)
    print(f"{'TOTAL MONTHLY':<20} ${total:>6.2f}")
    print(f"{'ANNUAL ESTIMATE':<20} ${total * 12:>6.2f}")
    print("=" * 50)

    # Cost optimization tips
    if environment == "development":
        print("\n💡 Development Tips:")
        print("   • Use t3.micro instances (AWS Free Tier eligible)")
        print("   • Minimal storage and backup requirements")
        print("   • Can be stopped outside working hours")

    elif environment == "staging":
        print("\n💡 Staging Tips:")
        print("   • Scale down when not actively testing")
        print("   • Use smaller instance sizes")
        print("   • Limited data retention")

    elif environment == "production":
        print("\n💡 Production Optimization:")
        print("   • Consider Reserved Instances (30-50% savings)")
        print("   • Set up auto-scaling policies")
        print("   • Implement cost monitoring alerts")
        print("   • Review and right-size resources monthly")


def main():
    """Main function."""
    if len(sys.argv) != 2:
        print("Usage: python simple_cost_estimator.py <environment>")
        print("Environments: development, staging, production")
        sys.exit(1)

    environment = sys.argv[1].lower()
    print_cost_estimate(environment)


if __name__ == "__main__":
    main()
