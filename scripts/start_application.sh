#!/bin/bash
echo "Starting application..."
cd /opt/viewpost || { echo "Failed to change directory"; exit 1; }
source venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Export Flask environment variables
export FLASK_APP=app.py
export FLASK_ENV=production
export PYTHONPATH=/opt/viewpost

# Log the environment for debugging
echo "Current directory: $(pwd)"
echo "Python path: $PYTHONPATH"
echo "Flask app: $FLASK_APP"

# Start the application
echo "Starting Flask application..."
python3 -m flask run --host=0.0.0.0 --port=5000 > /var/log/viewpost/application.log 2>&1 &
pid=$!

# Verify process started
if ps -p $pid > /dev/null; then
    echo $pid > /var/run/viewpost.pid
    echo "Application started successfully with PID: $pid"
    # Give Flask a moment to fully start
    sleep 5
    # Check if process is still running
    if ps -p $pid > /dev/null; then
        echo "Process verified running after startup"
    else
        echo "Process died after startup"
        exit 1
    fi
else
    echo "Failed to start application"
    exit 1
fi