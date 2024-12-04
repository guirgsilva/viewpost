# app/app.py
from flask import Flask, jsonify
import socket
import psutil
import time
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app(test_config=None):
    app = Flask(__name__)
    
    app.config.update(
        TESTING=False if test_config is None else True,
        SECRET_KEY='dev'
    )

    if test_config:
        app.config.update(test_config)

    request_count = 0

    def get_instance_info():
        return {
            'hostname': socket.gethostname(),
            'internal_ip': socket.gethostbyname(socket.gethostname()),
            'cpu_percent': psutil.cpu_percent(),
            'memory_percent': psutil.virtual_memory().percent
        }

    @app.route('/')
    def home():
        nonlocal request_count
        request_count += 1
        instance_info = get_instance_info()
        logger.info(f"Request received on instance {instance_info['hostname']}")
        
        return jsonify({
            'message': 'Welcome to ViewPost Test Application',
            'instance_info': instance_info,
            'request_count': request_count,
            'timestamp': datetime.now().isoformat()
        })

    @app.route('/health')
    def health():
        instance_info = get_instance_info()
        health_status = 'healthy'
        
        if instance_info['cpu_percent'] > 90 or instance_info['memory_percent'] > 90:
            health_status = 'unhealthy'
            return jsonify({'status': health_status}), 500
            
        return jsonify({
            'status': health_status,
            'checks': {
                'cpu': instance_info['cpu_percent'],
                'memory': instance_info['memory_percent']
            }
        })

    @app.route('/stress/<int:seconds>')
    def stress(seconds):
        if seconds > 60:
            seconds = 60
            
        logger.info(f"Starting stress test for {seconds} seconds")
        start_time = time.time()
        
        while time.time() - start_time < seconds:
            x = 234234 * 234234
            
        return jsonify({
            'message': f'Stress test completed for {seconds} seconds',
            'instance_info': get_instance_info()
        })

    @app.route('/error')
    def error():
        logger.error("Test error endpoint called")
        return jsonify({'error': 'Test error endpoint'}), 500

    return app

app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)