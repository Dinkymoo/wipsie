import json
import os
from datetime import (
    datetime,
)
from typing import (
    Any,
    Dict,
)

import requests


def lambda_handler(event, context):
    """
    Enhanced Data Poller Lambda Function - Staging Deployment
    Polls external APIs and stores data through the FastAPI backend
    Version: 1.0.0-staging
    """

    # Configuration from environment variables
    api_base_url = os.environ.get("API_BASE_URL", "http://localhost:8000")
    api_key = os.environ.get("WEATHER_API_KEY", "demo_key")

    try:
        # Get the source parameter from the event
        source = event.get("source", "weather")

        if source == "weather":
            result = poll_weather_data(api_key)
        elif source == "stocks":
            result = poll_stock_data()
        elif source == "news":
            result = poll_news_data()
        else:
            return {
                "statusCode": 400,
                "body": json.dumps(
                    {
                        "error": f"Unknown data source: {source}",
                        "supported_sources": ["weather", "stocks", "news"],
                    }
                ),
            }

        # Store the data through the FastAPI backend
        if (
            api_base_url != "http://localhost:8000"
        ):  # Only call API if not local dev
            store_result = store_data_via_api(api_base_url, result)
            result["storage_status"] = store_result

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Data polled successfully",
                    "source": source,
                    "data": result,
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(
                {
                    "error": str(e),
                    "message": "Failed to poll data",
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
        }


def poll_weather_data(api_key: str) -> Dict[str, Any]:
    """Poll weather data from OpenWeatherMap API"""
    cities = ["London", "New York", "Tokyo", "Sydney"]
    weather_data = []

    for city in cities:
        try:
            # Using a demo endpoint for testing - replace with actual API
            if api_key == "demo_key":
                # Return mock data for testing
                data = {
                    "name": city,
                    "main": {"temp": 20.5, "humidity": 65},
                    "weather": [{"description": "clear sky"}],
                }
            else:
                response = requests.get(
                    f"https://api.openweathermap.org/data/2.5/weather"
                    f"?q={city}&appid={api_key}&units=metric",
                    timeout=10,
                )
                response.raise_for_status()
                data = response.json()

            weather_data.append(
                {
                    "city": data.get("name", city),
                    "temperature": data.get("main", {}).get("temp"),
                    "humidity": data.get("main", {}).get("humidity"),
                    "description": data.get("weather", [{}])[0].get(
                        "description"
                    ),
                    "source": "weather_api",
                }
            )

        except Exception as e:
            weather_data.append(
                {"city": city, "error": str(e), "source": "weather_api"}
            )

    return {"weather_data": weather_data}


def poll_stock_data() -> Dict[str, Any]:
    """Poll stock data - mock implementation"""
    # This would integrate with a real stock API like Alpha Vantage
    stocks = ["AAPL", "GOOGL", "MSFT", "AMZN"]
    stock_data = []

    for symbol in stocks:
        # Mock data for demonstration
        stock_data.append(
            {
                "symbol": symbol,
                "price": round(150.0 + hash(symbol) % 100, 2),
                "change": round((hash(symbol) % 20 - 10) / 10, 2),
                "source": "stock_api",
            }
        )

    return {"stock_data": stock_data}


def poll_news_data() -> Dict[str, Any]:
    """Poll news data - mock implementation"""
    # This would integrate with a news API like NewsAPI
    news_data = [
        {
            "title": "Tech stocks surge on AI optimism",
            "summary": "Technology stocks continue their upward trend...",
            "source": "news_api",
            "category": "technology",
        },
        {
            "title": "Climate change impacts global weather patterns",
            "summary": "Scientists report significant changes in weather...",
            "source": "news_api",
            "category": "environment",
        },
    ]

    return {"news_data": news_data}


def store_data_via_api(
    api_base_url: str, data: Dict[str, Any]
) -> Dict[str, Any]:
    """Store polled data through the FastAPI backend"""
    try:
        # Flatten the data for storage
        data_points = []

        for key, value in data.items():
            if isinstance(value, list):
                for i, item in enumerate(value):
                    data_points.append(
                        {
                            "name": f"{key}_{i}",
                            "value": json.dumps(item),
                            "source": "lambda_poller",
                        }
                    )

        # Send to API
        response = requests.post(
            f"{api_base_url}/api/data-points/",
            json=(
                data_points[0]
                if data_points
                else {
                    "name": "empty",
                    "value": "{}",
                    "source": "lambda_poller",
                }
            ),
            headers={"Content-Type": "application/json"},
            timeout=10,
        )
        response.raise_for_status()

        return {"status": "success", "stored_points": len(data_points)}

    except Exception as e:
        return {"status": "error", "error": str(e)}
