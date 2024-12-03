#!/bin/bash
echo "Starting application..."
cd /opt/viewpost
source venv/bin/activate
export FLASK_APP=app.app
nohup flask run --host=0.0.0.0 --port=80 > /var/log/viewpost/application.log 2>&1 &
echo $! > /var/run/viewpost.pid