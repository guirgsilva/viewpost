#!/bin/bash
echo "Stopping application..."
if [ -f /var/run/viewpost.pid ]; then
    pid=$(cat /var/run/viewpost.pid)
    kill -15 $pid
    rm /var/run/viewpost.pid
fi