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
    """Configure logging system with fallback for test environments"""
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    # Determine log location based on environment
    if os.getenv('FLASK_ENV') == 'testing':
        log_file = 'test_application.log'
    else:
        log_dir = '/var/log/viewpost'
        # Create log directory if it doesn't exist
        os.makedirs(log_dir, exist_ok=True)
        log_file = os.path.join(log_dir, 'application.log')

    logging.basicConfig(
        level=logging.INFO,
        format=log_format,
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger(__name__)

# Initialize logging with error handling
try:
    logger = setup_logging()
except Exception as e:
    # Fallback to basic logging if file logging fails
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[logging.StreamHandler(sys.stdout)]
    )
    logger = logging.getLogger(__name__)
    logger.warning(f"Failed to setup file logging: {str(e)}. Using console logging only.")

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

    @app.route('/')
    def home():
        """
        Main route that shows instance information and request counter.
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
        """
        max_seconds = min(seconds, 60)
        logger.info(f"Starting stress test for {max_seconds} seconds")
        start_time = time.time()
        
        while time.time() - start_time < max_seconds:
            x = 234234 * 234234
        
        return jsonify({
            'message': f'Stress test completed in {time.time() - start_time:.2f} seconds',
            'instance_info': get_instance_info()
        })

    return app

# Create the application instance
app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)