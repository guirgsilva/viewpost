#!/bin/bash
echo "Preparing environment for installation..."
yum update -y
yum install -y python3-pip git python3-devel gcc
yum install -y python3-psutil
mkdir -p /opt/viewpost
mkdir -p /var/log/viewpost
chown -R ec2-user:ec2-user /var/log/viewpost
chmod 755 /var/log/viewpost