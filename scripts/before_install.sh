#!/bin/bash
# before_install.sh
echo "Preparing environment for installation..."
# Install system dependencies with error checking
yum update -y || { echo "Failed to update system packages"; exit 1; }
yum install -y python3-pip git python3-devel gcc python3-psutil || { echo "Failed to install dependencies"; exit 1; }

# Create directories with proper permissions
mkdir -p /opt/viewpost /var/log/viewpost
chown -R ec2-user:ec2-user /opt/viewpost /var/log/viewpost
chmod 755 /var/log/viewpost

# Clean up old deployment if exists
if [ -f /var/run/viewpost.pid ]; then
    ./scripts/stop_application.sh
fi
