#!/bin/bash
# after_install.sh
echo "Configuring application..."
cd /opt/viewpost || { echo "Failed to change directory"; exit 1; }

# Create and configure virtual environment
python3 -m venv venv || { echo "Failed to create virtual environment"; exit 1; }
source venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Install dependencies with error checking
pip install --upgrade pip || { echo "Failed to upgrade pip"; exit 1; }
pip install -r requirements.txt || { echo "Failed to install requirements"; exit 1; }

# Set correct permissions
chown -R ec2-user:ec2-user /opt/viewpost/venv