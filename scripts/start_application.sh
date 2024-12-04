#!/bin/bash
echo "Starting application..."

# Configuration
APP_DIR="/opt/viewpost"
LOG_DIR="/var/log/viewpost"
PID_FILE="/var/run/viewpost.pid"
APP_PORT=5000

# Ensure we're in the right directory
cd $APP_DIR || { echo "Failed to change to application directory"; exit 1; }

# Activate virtual environment
source venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Export environment variables
export FLASK_APP=app.py
export FLASK_ENV=production
export PYTHONPATH=$APP_DIR

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR
chown -R ec2-user:ec2-user $LOG_DIR

# Log startup information
echo "Starting application at $(date)"
echo "Current directory: $(pwd)"
echo "Python path: $PYTHONPATH"
echo "Flask app: $FLASK_APP"

# Start the application
echo "Starting Flask application on port $APP_PORT..."
python3 -m flask run --host=0.0.0.0 --port=$APP_PORT > $LOG_DIR/application.log 2>&1 &
pid=$!

# Verify process started
if ps -p $pid > /dev/null; then
    echo $pid > $PID_FILE
    echo "Application started successfully with PID: $pid"
    
    # Give Flask a moment to fully start
    sleep 5
    
    # Verify process is still running and responding
    if ps -p $pid > /dev/null && curl -s http://localhost:$APP_PORT/health > /dev/null; then
        echo "Application verified running and responding"
    else
        echo "Process started but not responding properly"
        exit 1
    fi
else
    echo "Failed to start application"
    exit 1
fi