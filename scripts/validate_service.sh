#!/bin/bash
echo "Validating service..."

# Configuration
MAX_ATTEMPTS=30
SLEEP_TIME=10
APP_PORT=5000
ENDPOINT="http://localhost:${APP_PORT}/health"
LOG_FILE="/var/log/viewpost/application.log"
PID_FILE="/var/run/viewpost.pid"

check_service() {
    echo "=== Checking Service Status ==="
    echo "Timestamp: $(date)"
    echo "Current directory: $(pwd)"
    
    # Check process status
    if [ -f $PID_FILE ]; then
        pid=$(cat $PID_FILE)
        echo "Process status for PID $pid:"
        ps -f -p $pid || echo "Process not found"
    else
        echo "No PID file found at $PID_FILE"
    fi
    
    # Check port status
    echo "Port status:"
    netstat -tulpn | grep :$APP_PORT || echo "No process listening on port $APP_PORT"
    
    # Check application logs
    echo "Recent application logs:"
    tail -n 10 $LOG_FILE 2>/dev/null || echo "No recent logs found"
    
    # Attempt health check
    echo "Attempting health check: $ENDPOINT"
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
    
    # On every 5th attempt, perform detailed diagnostics
    if [ $((i % 5)) -eq 0 ]; then
        echo "=== Detailed Diagnostics ==="
        echo "System memory status:"
        free -m
        echo "Disk usage:"
        df -h
        echo "Process list:"
        ps aux | grep -E "python|flask"
    fi
    
    sleep $SLEEP_TIME
done

echo "Service validation failed after $MAX_ATTEMPTS attempts"
echo "=== Final Diagnostics ==="
echo "Complete application log:"
cat $LOG_FILE
echo "System status:"
top -b -n 1
exit 1