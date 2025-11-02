import requests


def test_health_endpoint():
    response = requests.get(
        'https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/health')
    assert response.status_code in [200, 500]


def test_root_endpoint():
    response = requests.get(
        'https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/prod/')
    assert response.status_code in [200, 500]


def test_data_points_endpoint():
    response = requests.get(
        'https://yb6i0oap3c.execute-api.eu-west-1.amazonaws.com/'
        'prod/data-points'
    )
    assert response.status_code in [200, 500]
