#!/usr/bin/env python3
"""
AWS Cost Estimation Tool for Wipsie Application
Estimates monthly costs for AWS resources used in the project.
"""

import argparse
import json
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict


@dataclass
class CostEstimate:
    service: str
    resource: str
    monthly_cost: float
    unit: str
    assumptions: str


class AWSCostCalculator:
    """Calculate estimated AWS costs for Wipsie resources."""

    # AWS Pricing (EU-West-1, as of 2024)
    LAMBDA_PRICING = {
        "request_price": 0.0000002,  # $0.20 per 1M requests
        "gb_second_price": 0.0000166667,  # Per GB-second
        "free_requests": 1_000_000,  # Free tier
        "free_gb_seconds": 400_000,  # Free tier
    }

    S3_PRICING = {
        "standard_storage": 0.023,  # Per GB/month
        "requests_put": 0.0000051,  # Per 1000 requests
        "requests_get": 0.0000004,  # Per 1000 requests
        "data_transfer": 0.09,  # Per GB after first 1GB free
    }

    RDS_PRICING = {
        "db_t3_micro": 0.017,  # Per hour
        "db_t3_small": 0.034,  # Per hour
        "db_t3_medium": 0.068,  # Per hour
        "storage_gp2": 0.115,  # Per GB/month
    }

    SQS_PRICING = {
        "requests": 0.0000004,  # Per request after first 1M free
        "free_requests": 1_000_000,  # Free tier
    }

    SES_PRICING = {
        "email_cost": 0.10,  # Per 1000 emails
        "free_emails": 62_000,  # Free tier (if sent from EC2)
    }

    CLOUDFRONT_PRICING = {
        "data_transfer_first_10tb": 0.085,  # Per GB
        "requests_per_10k": 0.0075,  # Per 10,000 requests
    }

    def __init__(self, usage_profile: str = "development"):
        """Initialize with usage profile (development, staging, production)."""
        self.usage_profile = usage_profile
        self.estimates = []

        # Usage assumptions based on profile
        self.usage_assumptions = self._get_usage_assumptions(usage_profile)

    def _get_usage_assumptions(self, profile: str) -> Dict[str, Any]:
        """Get usage assumptions for different profiles."""
        profiles = {
            "learning": {
                "lambda_invocations_per_month": 5_000,  # Well within free tier
                "lambda_avg_duration_ms": 800,
                "lambda_memory_mb": 128,  # Minimal memory for learning
                "s3_storage_gb": 2,  # Within 5GB free tier
                "s3_requests_per_month": 500,  # Within 20K free tier
                "rds_instance_type": "db.t3.micro",  # Free tier eligible
                "rds_storage_gb": 15,  # Within 20GB free tier
                # Only when actively learning (not 24/7)
                "rds_hours_per_month": 300,
                "sqs_requests_per_month": 10_000,  # Well within 1M free tier
                "ses_emails_per_month": 100,  # Minimal email testing
                "cloudfront_data_transfer_gb": 2,  # Within 1TB free tier
                "cloudfront_requests": 1_000,  # Minimal for learning
            },
            "development": {
                "lambda_invocations_per_month": 10_000,
                "lambda_avg_duration_ms": 1000,
                "lambda_memory_mb": 256,
                "s3_storage_gb": 1,
                "s3_requests_per_month": 1_000,
                "rds_instance_type": "db.t3.micro",
                "rds_storage_gb": 20,
                "rds_hours_per_month": 730,  # Always on
                "sqs_requests_per_month": 50_000,
                "ses_emails_per_month": 1_000,
                "cloudfront_data_transfer_gb": 5,
                "cloudfront_requests": 10_000,
            },
            "staging": {
                "lambda_invocations_per_month": 100_000,
                "lambda_avg_duration_ms": 1500,
                "lambda_memory_mb": 512,
                "s3_storage_gb": 10,
                "s3_requests_per_month": 10_000,
                "rds_instance_type": "db.t3.small",
                "rds_storage_gb": 50,
                "rds_hours_per_month": 730,
                "sqs_requests_per_month": 500_000,
                "ses_emails_per_month": 10_000,
                "cloudfront_data_transfer_gb": 50,
                "cloudfront_requests": 100_000,
            },
            "production": {
                "lambda_invocations_per_month": 1_000_000,
                "lambda_avg_duration_ms": 2000,
                "lambda_memory_mb": 1024,
                "s3_storage_gb": 100,
                "s3_requests_per_month": 100_000,
                "rds_instance_type": "db.t3.medium",
                "rds_storage_gb": 200,
                "rds_hours_per_month": 730,
                "sqs_requests_per_month": 5_000_000,
                "ses_emails_per_month": 100_000,
                "cloudfront_data_transfer_gb": 500,
                "cloudfront_requests": 1_000_000,
            },
        }
        return profiles.get(profile, profiles["learning"])

    def calculate_lambda_costs(self) -> None:
        """Calculate Lambda function costs."""
        usage = self.usage_assumptions

        # Calculate compute costs
        gb_seconds = (
            usage["lambda_invocations_per_month"]
            * (usage["lambda_avg_duration_ms"] / 1000)
            * (usage["lambda_memory_mb"] / 1024)
        )

        # Apply free tier
        billable_requests = max(
            0,
            usage["lambda_invocations_per_month"]
            - self.LAMBDA_PRICING["free_requests"],
        )
        billable_gb_seconds = max(
            0, gb_seconds - self.LAMBDA_PRICING["free_gb_seconds"]
        )

        request_cost = billable_requests * self.LAMBDA_PRICING["request_price"]
        compute_cost = (
            billable_gb_seconds * self.LAMBDA_PRICING["gb_second_price"]
        )

        total_cost = request_cost + compute_cost

        self.estimates.append(
            CostEstimate(
                service="AWS Lambda",
                resource="Lambda Functions (data_poller + task_processor)",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=f"{usage['lambda_invocations_per_month']:,} invocations, "
                f"{usage['lambda_memory_mb']}MB memory, "
                f"{usage['lambda_avg_duration_ms']}ms avg duration",
            )
        )

    def calculate_s3_costs(self) -> None:
        """Calculate S3 storage costs."""
        usage = self.usage_assumptions

        storage_cost = (
            usage["s3_storage_gb"] * self.S3_PRICING["standard_storage"]
        )
        request_cost = (
            usage["s3_requests_per_month"] / 1000
        ) * self.S3_PRICING["requests_put"]

        total_cost = storage_cost + request_cost

        self.estimates.append(
            CostEstimate(
                service="Amazon S3",
                resource="Frontend hosting + Lambda packages",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=f"{usage['s3_storage_gb']}GB storage, "
                f"{usage['s3_requests_per_month']:,} requests/month",
            )
        )

    def calculate_rds_costs(self) -> None:
        """Calculate RDS PostgreSQL costs."""
        usage = self.usage_assumptions

        # For learning profile, use Free Tier (750 hours/month for 12 months)
        if self.usage_profile == "learning":
            free_tier_hours = 750  # AWS Free Tier limit
            billable_hours = max(
                0, usage["rds_hours_per_month"] - free_tier_hours
            )
            instance_cost = (
                billable_hours * self.RDS_PRICING[usage["rds_instance_type"]]
            )

            # Storage within 20GB is free for first 12 months
            free_storage_gb = 20
            billable_storage = max(
                0, usage["rds_storage_gb"] - free_storage_gb
            )
            storage_cost = billable_storage * self.RDS_PRICING["storage_gp2"]
        else:
            instance_cost = (
                usage["rds_hours_per_month"]
                * self.RDS_PRICING[usage["rds_instance_type"]]
            )
            storage_cost = (
                usage["rds_storage_gb"] * self.RDS_PRICING["storage_gp2"]
            )

        total_cost = instance_cost + storage_cost

        assumptions = (
            f"{usage['rds_instance_type']}, "
            f"{usage['rds_storage_gb']}GB storage"
        )

        if self.usage_profile == "learning":
            assumptions += f", {usage['rds_hours_per_month']} hours/month (Free Tier: 750h)"
        else:
            assumptions += f", Always on (730 hours/month)"

        self.estimates.append(
            CostEstimate(
                service="Amazon RDS",
                resource=f"PostgreSQL ({usage['rds_instance_type']})",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=assumptions,
            )
        )

    def calculate_sqs_costs(self) -> None:
        """Calculate SQS costs."""
        usage = self.usage_assumptions

        billable_requests = max(
            0,
            usage["sqs_requests_per_month"]
            - self.SQS_PRICING["free_requests"],
        )
        total_cost = billable_requests * self.SQS_PRICING["requests"]

        self.estimates.append(
            CostEstimate(
                service="Amazon SQS",
                resource="Message Queues (default, data-polling, task-processing, notifications)",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=f"{usage['sqs_requests_per_month']:,} requests/month "
                f"(first 1M free)",
            )
        )

    def calculate_ses_costs(self) -> None:
        """Calculate SES email costs."""
        usage = self.usage_assumptions

        billable_emails = max(
            0, usage["ses_emails_per_month"] - self.SES_PRICING["free_emails"]
        )
        total_cost = (billable_emails / 1000) * self.SES_PRICING["email_cost"]

        self.estimates.append(
            CostEstimate(
                service="Amazon SES",
                resource="Email notifications",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=f"{usage['ses_emails_per_month']:,} emails/month "
                f"(first 62K free if sent from EC2)",
            )
        )

    def calculate_cloudfront_costs(self) -> None:
        """Calculate CloudFront CDN costs."""
        usage = self.usage_assumptions

        data_transfer_cost = (
            usage["cloudfront_data_transfer_gb"]
            * self.CLOUDFRONT_PRICING["data_transfer_first_10tb"]
        )
        request_cost = (
            usage["cloudfront_requests"] / 10000
        ) * self.CLOUDFRONT_PRICING["requests_per_10k"]

        total_cost = data_transfer_cost + request_cost

        self.estimates.append(
            CostEstimate(
                service="Amazon CloudFront",
                resource="CDN for frontend distribution",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=f"{usage['cloudfront_data_transfer_gb']}GB data transfer, "
                f"{usage['cloudfront_requests']:,} requests/month",
            )
        )

    def calculate_github_actions_costs(self) -> None:
        """Calculate GitHub Actions costs."""
        # For learning, assume public repository (free)
        if self.usage_profile == "learning":
            total_cost = 0.00  # Public repos are free
            assumptions = "Public repository - unlimited minutes (free)"
        else:
            # Estimate workflow runtime for private repos
            workflows_per_day = {
                "development": 5,  # Few commits per day
                "staging": 10,  # More active development
                "production": 3,  # Only main branch merges
            }

            daily_workflows = workflows_per_day.get(self.usage_profile, 5)
            monthly_workflows = daily_workflows * 30

            # Estimate minutes per workflow run
            minutes_per_run = 15  # Average across all workflows
            total_minutes = monthly_workflows * minutes_per_run

            # GitHub pricing (private repo)
            free_minutes = 2000
            billable_minutes = max(0, total_minutes - free_minutes)
            cost_per_minute = 0.008

            total_cost = billable_minutes * cost_per_minute
            assumptions = (
                f"{daily_workflows} workflows/day, "
                f"{minutes_per_run} min/workflow, "
                f"{total_minutes} total minutes/month"
            )

        self.estimates.append(
            CostEstimate(
                service="GitHub Actions",
                resource="CI/CD workflows",
                monthly_cost=total_cost,
                unit="USD",
                assumptions=assumptions,
            )
        )

    def calculate_all_costs(self) -> None:
        """Calculate all cost estimates."""
        self.calculate_lambda_costs()
        self.calculate_s3_costs()
        self.calculate_rds_costs()
        self.calculate_sqs_costs()
        self.calculate_ses_costs()
        self.calculate_cloudfront_costs()
        self.calculate_github_actions_costs()

    def get_total_cost(self) -> float:
        """Get total estimated monthly cost."""
        return sum(estimate.monthly_cost for estimate in self.estimates)

    def print_report(self) -> None:
        """Print detailed cost report."""
        print(f"\n🧮 AWS Cost Estimation Report")
        print(f"{'=' * 50}")
        print(f"Profile: {self.usage_profile.title()}")
        print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'=' * 50}\n")

        total_cost = 0
        for estimate in self.estimates:
            print(f"💰 {estimate.service}")
            print(f"   Resource: {estimate.resource}")
            print(
                f"   Monthly Cost: ${estimate.monthly_cost:.2f} {estimate.unit}"
            )
            print(f"   Assumptions: {estimate.assumptions}")
            print()
            total_cost += estimate.monthly_cost

        print(f"{'=' * 50}")
        print(f"🎯 TOTAL ESTIMATED MONTHLY COST: ${total_cost:.2f} USD")
        print(f"🎯 ANNUAL ESTIMATE: ${total_cost * 12:.2f} USD")
        print(f"{'=' * 50}")

        # Cost breakdown by service
        print(f"\n📊 Cost Breakdown:")
        for estimate in sorted(
            self.estimates, key=lambda x: x.monthly_cost, reverse=True
        ):
            percentage = (
                (estimate.monthly_cost / total_cost) * 100
                if total_cost > 0
                else 0
            )
            print(
                f"   {estimate.service:<20} ${estimate.monthly_cost:>6.2f} ({percentage:4.1f}%)"
            )

    def export_json(self, filename: str = None) -> str:
        """Export cost estimates to JSON."""
        if not filename:
            filename = f"cost_estimate_{self.usage_profile}_{datetime.now().strftime('%Y%m%d')}.json"

        data = {
            "profile": self.usage_profile,
            "generated_at": datetime.now().isoformat(),
            "total_monthly_cost": self.get_total_cost(),
            "total_annual_cost": self.get_total_cost() * 12,
            "estimates": [
                {
                    "service": est.service,
                    "resource": est.resource,
                    "monthly_cost": est.monthly_cost,
                    "unit": est.unit,
                    "assumptions": est.assumptions,
                }
                for est in self.estimates
            ],
        }

        with open(filename, "w") as f:
            json.dump(data, f, indent=2)

        return filename


def main():
    parser = argparse.ArgumentParser(
        description="Estimate AWS costs for Wipsie application"
    )
    parser.add_argument(
        "--profile",
        choices=["learning", "development", "staging", "production"],
        default="learning",
        help="Usage profile for cost estimation (learning uses AWS Free Tier)",
    )
    parser.add_argument(
        "--export", action="store_true", help="Export results to JSON file"
    )
    parser.add_argument("--output", help="Output filename for JSON export")

    args = parser.parse_args()

    calculator = AWSCostCalculator(args.profile)
    calculator.calculate_all_costs()
    calculator.print_report()

    if args.export:
        filename = calculator.export_json(args.output)
        print(f"\n📄 Cost estimate exported to: {filename}")


if __name__ == "__main__":
    main()
