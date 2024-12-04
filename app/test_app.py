# app/test_app.py
import pytest
from app import create_app

@pytest.fixture
def app():
    app = create_app({'TESTING': True})
    return app

@pytest.fixture
def client(app):
    return app.test_client()

def test_home_route(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b'Welcome to ViewPost Test Application' in response.data

def test_health_route(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert b'status' in response.data
    assert b'healthy' in response.data

def test_stress_route(client):
    response = client.get('/stress/1')
    assert response.status_code == 200
    assert b'Stress test completed' in response.data
    assert b'instance_info' in response.data