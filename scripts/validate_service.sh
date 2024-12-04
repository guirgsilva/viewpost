#!/bin/bash
echo "Validating service..."

MAX_ATTEMPTS=30
SLEEP_TIME=10
ENDPOINT="http://localhost:5000/health"

check_service() {
    echo "Checking service status..."
    echo "Current directory: $(pwd)"
    echo "Python processes running:"
    ps aux | grep python
    echo "Network connections:"
    netstat -tulpn | grep :5000
    echo "Attempting to connect to endpoint: $ENDPOINT"
    
    curl -v "$ENDPOINT" 2>&1
    return $?
}

# Initial delay to allow application to start
sleep 5

for ((i=1; i<=$MAX_ATTEMPTS; i++)); do
    echo "Attempt $i of $MAX_ATTEMPTS to validate service..."
    
    if check_service; then
        echo "Service is running successfully!"
        exit 0
    fi
    
    # Show detailed diagnostics every 5 attempts
    if [ $((i % 5)) -eq 0 ]; then
        echo "=== Diagnostic Information ==="
        echo "Application Log:"
        tail -n 50 /var/log/viewpost/application.log
        echo "Process Status:"
        if [ -f /var/run/viewpost.pid ]; then
            pid=$(cat /var/run/viewpost.pid)
            ps -f -p $pid || echo "Process not found"
        fi
        echo "========================="
    fi
    
    sleep $SLEEP_TIME
done

echo "Service validation failed after $MAX_ATTEMPTS attempts"
echo "Final Application Log:"
tail -n 100 /var/log/viewpost/application.log
exit 1