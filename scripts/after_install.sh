#!/bin/bash
echo "Configuring application..."
cd /opt/viewpost
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt