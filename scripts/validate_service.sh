#!/bin/bash
# validate_service.sh
echo "Validating service..."

MAX_ATTEMPTS=30
SLEEP_TIME=10
ENDPOINT="http://localhost:5000/health"

check_service() {
    local response
    response=$(curl -s -f "$ENDPOINT")
    local status=$?
    
    if [ $status -ne 0 ]; then
        echo "Service check failed. Checking logs..."
        tail -n 20 /var/log/viewpost/application.log
        return 1
    fi
    return 0
}

# Initial delay to allow application to start
sleep 5

for ((i=1; i<=$MAX_ATTEMPTS; i++)); do
    echo "Attempt $i of $MAX_ATTEMPTS to validate service..."
    
    if check_service; then
        echo "Service is running successfully!"
        exit 0
    fi
    
    # Show process status every 5 attempts
    if [ $((i % 5)) -eq 0 ]; then
        echo "Process status:"
        if [ -f /var/run/viewpost.pid ]; then
            pid=$(cat /var/run/viewpost.pid)
            ps -p $pid || echo "Process not found"
        else
            echo "No PID file found"
        fi
    fi
    
    sleep $SLEEP_TIME
done

echo "Service validation failed after $MAX_ATTEMPTS attempts"
echo "Last 50 lines of application log:"
tail -n 50 /var/log/viewpost/application.log
exit 1