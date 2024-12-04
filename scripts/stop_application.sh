#!/bin/bash
# stop_application.sh
echo "Stopping application..."
if [ -f /var/run/viewpost.pid ]; then
    pid=$(cat /var/run/viewpost.pid)
    # Try graceful shutdown first
    kill -15 $pid 2>/dev/null || true
    # Wait a bit and force kill if still running
    sleep 5
    if ps -p $pid > /dev/null; then
        kill -9 $pid 2>/dev/null || true
    fi
    rm /var/run/viewpost.pid
    echo "Application stopped successfully"
else
    echo "No PID file found"
fi