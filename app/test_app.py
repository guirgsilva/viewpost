"""
Test suite for ViewPost Application
"""
import os
import pytest
from app import create_app

@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    # Set testing environment
    os.environ['FLASK_ENV'] = 'testing'
    
    app = create_app({
        'TESTING': True,
    })
    return app

@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

def test_home_route(client):
    """Test that home route returns correct response"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data
    assert 'Welcome to ViewPost Test Application' in data['message']
    assert 'instance_info' in data

def test_health_route(client):
    """Test that health check returns correct response"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert 'status' in data
    assert data['status'] == 'healthy'
    assert 'checks' in data

def test_stress_route(client):
    """Test that stress route works correctly"""
    response = client.get('/stress/1')
    assert response.status_code == 200
    data = response.get_json()
    assert 'message' in data
    assert 'instance_info' in data