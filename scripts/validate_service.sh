#!/bin/bash
echo "Validating service..."
for i in {1..30}; do
    if curl -s http://localhost/health; then
        echo "Application is running successfully"
        exit 0
    fi
    echo "Waiting for application to start... ($i/30)"
    sleep 10
done
echo "Application failed to start properly"
exit 1