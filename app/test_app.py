# app/test_app.py
import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_route(client):
    """Test that home route returns 200"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Welcome to ViewPost Test Application' in response.data

def test_health_route(client):
    """Test that health check route returns 200"""
    response = client.get('/health')
    assert response.status_code == 200
    assert b'status' in response.data

def test_stress_route(client):
    """Test that stress route works"""
    response = client.get('/stress/1')
    assert response.status_code == 200
    assert b'Stress test completed' in response.data