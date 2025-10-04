#!/usr/bin/env python3
"""
Deployment Cost Calculator
Shows costs based on deployment frequency
"""


def calculate_deployment_costs():
    """Calculate costs for different deployment frequencies."""

    # Per deployment costs
    github_minutes_per_deploy = 25  # Average workflow time
    cost_per_minute = 0.008
    deploy_cost = github_minutes_per_deploy * cost_per_minute

    scenarios = {
        "Conservative (1/week)": {
            "deploys_per_month": 4,
            "description": "Weekly releases, careful testing",
        },
        "Moderate (2/week)": {
            "deploys_per_month": 8,
            "description": "Bi-weekly releases, regular updates",
        },
        "Agile (daily)": {
            "deploys_per_month": 22,
            "description": "Daily deployments, CI/CD",
        },
        "Heavy (multiple/day)": {
            "deploys_per_month": 60,
            "description": "Multiple daily deployments",
        },
    }

    print("🚀 Deployment Cost Analysis")
    print("=" * 60)
    print(f"Cost per deployment: ${deploy_cost:.2f}")
    print("=" * 60)

    for scenario, data in scenarios.items():
        monthly_deploy_cost = data["deploys_per_month"] * deploy_cost
        annual_deploy_cost = monthly_deploy_cost * 12

        print(f"\n📈 {scenario}")
        print(f"   {data['description']}")
        print(f"   Deployments/month: {data['deploys_per_month']}")
        print(f"   Monthly deploy cost: ${monthly_deploy_cost:.2f}")
        print(f"   Annual deploy cost: ${annual_deploy_cost:.2f}")

        # Show percentage of total infrastructure cost
        total_monthly = 203.00  # From production estimate
        percentage = (monthly_deploy_cost / total_monthly) * 100
        print(f"   % of total monthly cost: {percentage:.1f}%")


if __name__ == "__main__":
    calculate_deployment_costs()
