#!/bin/bash
# start_application.sh
echo "Starting application..."
cd /opt/viewpost || { echo "Failed to change directory"; exit 1; }
source venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Kill any existing process
if [ -f /var/run/viewpost.pid ]; then
    old_pid=$(cat /var/run/viewpost.pid)
    kill -15 $old_pid 2>/dev/null || true
    rm /var/run/viewpost.pid
fi

# Export environment variables
export FLASK_APP=app.app
export FLASK_ENV=production
# Important: Using port 5000 to match validate_service.sh
nohup flask run --host=0.0.0.0 --port=5000 > /var/log/viewpost/application.log 2>&1 &
pid=$!

# Verify process started
if ps -p $pid > /dev/null; then
    echo $pid > /var/run/viewpost.pid
    echo "Application started successfully with PID: $pid"
else
    echo "Failed to start application"
    exit 1
fi
