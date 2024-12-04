"""
ViewPost Test Application
------------------------
A Flask application that demonstrates resource monitoring and high availability.
"""

import os
from flask import Flask, jsonify, request
import socket
import psutil
import time
import logging
from datetime import datetime
import sys

def setup_logging():
    """Configure logging system with detailed format and multiple handlers"""
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
        handlers=[
            logging.FileHandler('/var/log/viewpost/application.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger(__name__)

logger = setup_logging()

def create_app(test_config=None):
    """
    Factory function to create and configure the Flask application.
    Allows different configurations for testing and production.
    """
    app = Flask(__name__)
    
    # Base application configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        TESTING=False,
        DEBUG=False
    )

    # Override with test config if provided
    if test_config is not None:
        app.config.update(test_config)

    # Request counter for load balancing demonstration
    request_count = 0

    def get_instance_info():
        """
        Collect information about the current instance.
        Returns important metrics like CPU and memory usage.
        """
        try:
            return {
                'hostname': socket.gethostname(),
                'internal_ip': socket.gethostbyname(socket.gethostname()),
                'cpu_percent': psutil.cpu_percent(interval=1),
                'memory_percent': psutil.virtual_memory().percent,
                'disk_usage': psutil.disk_usage('/').percent
            }
        except Exception as e:
            logger.error(f"Error collecting instance information: {str(e)}")
            return {
                'error': 'Failed to collect metrics',
                'message': str(e)
            }

    @app.before_request
    def before_request():
        """Log information before each request"""
        logger.info(f"Received request for: {request.path}")

    @app.after_request
    def after_request(response):
        """
        Add security and performance headers after each request
        """
        response.headers['Server'] = 'ViewPost Test App'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'SAMEORIGIN'
        return response

    @app.route('/')
    def home():
        """
        Main route that shows instance information and request counter.
        Useful for demonstrating load balancing.
        """
        nonlocal request_count
        request_count += 1
        
        instance_info = get_instance_info()
        logger.info(f"Request processed on instance {instance_info['hostname']}")
        
        return jsonify({
            'message': 'Welcome to ViewPost Test Application',
            'instance_info': instance_info,
            'request_count': request_count,
            'timestamp': datetime.now().isoformat()
        })

    @app.route('/health')
    def health():
        """
        Health check endpoint for ALB.
        Returns health status based on system metrics.
        """
        instance_info = get_instance_info()
        
        # Check if metrics are within acceptable limits
        is_healthy = all([
            instance_info.get('cpu_percent', 100) < 90,
            instance_info.get('memory_percent', 100) < 90,
            instance_info.get('disk_usage', 100) < 90
        ])
        
        status = 'healthy' if is_healthy else 'unhealthy'
        status_code = 200 if is_healthy else 500
        
        response = {
            'status': status,
            'timestamp': datetime.now().isoformat(),
            'checks': {
                'cpu': instance_info.get('cpu_percent'),
                'memory': instance_info.get('memory_percent'),
                'disk': instance_info.get('disk_usage')
            }
        }
        
        return jsonify(response), status_code

    @app.route('/stress/<int:seconds>')
    def stress(seconds):
        """
        Endpoint for load testing.
        Allows testing application behavior under stress.
        """
        # Safety limit for stress test
        max_seconds = min(seconds, 60)
        
        logger.info(f"Starting stress test for {max_seconds} seconds")
        start_time = time.time()
        
        # Simulate CPU load
        while time.time() - start_time < max_seconds:
            x = 234234 * 234234
        
        end_time = time.time()
        duration = end_time - start_time
        
        return jsonify({
            'message': f'Stress test completed in {duration:.2f} seconds',
            'requested_duration': seconds,
            'actual_duration': duration,
            'instance_info': get_instance_info()
        })

    @app.route('/error')
    def error():
        """
        Test endpoint for error monitoring.
        Generates a test error for monitoring systems.
        """
        logger.error("Test error endpoint called")
        return jsonify({
            'error': 'Test error endpoint',
            'timestamp': datetime.now().isoformat()
        }), 500

    # Error handlers
    @app.errorhandler(404)
    def not_found_error(error):
        return jsonify({'error': 'Resource not found'}), 404

    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500

    return app

# Create the application instance
app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)