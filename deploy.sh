#!/bin/bash

# Function to wait for stack completion
wait_for_stack() {
    local stack_name=$1
    echo "Waiting for $stack_name to complete..."
    
    while true; do
        STATUS=$(aws cloudformation describe-stacks --stack-name $stack_name --query "Stacks[0].StackStatus" --output text)
        echo "Current status of $stack_name: $STATUS"
        
        if [[ "$STATUS" == "CREATE_COMPLETE" || "$STATUS" == "UPDATE_COMPLETE" ]]; then
            echo "$stack_name created/updated successfully!"
            break
        elif [[ "$STATUS" == "ROLLBACK_COMPLETE" || "$STATUS" == "DELETE_COMPLETE" || "$STATUS" == "UPDATE_ROLLBACK_COMPLETE" ]]; then
            echo "Error: $stack_name failed with status $STATUS"
            exit 1
        fi
        sleep 10
    done
}

echo "Starting infrastructure deployment..."

# 1. NetworkStack
echo "Deploying NetworkStack using network.yaml"
aws cloudformation deploy \
    --stack-name NetworkStack \
    --template-file cloudformation/network.yaml \
    --capabilities CAPABILITY_NAMED_IAM

wait_for_stack "NetworkStack"

# Get Network outputs
VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name NetworkStack \
    --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' \
    --output text)

PRIVATE_SUBNET_1=$(aws cloudformation describe-stacks \
    --stack-name NetworkStack \
    --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnet1`].OutputValue' \
    --output text)

PRIVATE_SUBNET_2=$(aws cloudformation describe-stacks \
    --stack-name NetworkStack \
    --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnet2`].OutputValue' \
    --output text)

PUBLIC_SUBNET_1=$(aws cloudformation describe-stacks \
    --stack-name NetworkStack \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1`].OutputValue' \
    --output text)

PUBLIC_SUBNET_2=$(aws cloudformation describe-stacks \
    --stack-name NetworkStack \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet2`].OutputValue' \
    --output text)

# 2. StorageStack
echo "Deploying StorageStack using storage.yaml"
aws cloudformation deploy \
    --stack-name StorageStack \
    --template-file cloudformation/storage.yaml \
    --capabilities CAPABILITY_NAMED_IAM

wait_for_stack "StorageStack"

# 3. DatabaseStack
echo "Deploying DatabaseStack using database.yaml"
aws cloudformation deploy \
    --stack-name DatabaseStack \
    --template-file cloudformation/database.yaml \
    --parameter-overrides \
        VPCId=$VPC_ID \
        PrivateSubnet1=$PRIVATE_SUBNET_1 \
        PrivateSubnet2=$PRIVATE_SUBNET_2 \
    --capabilities CAPABILITY_NAMED_IAM

wait_for_stack "DatabaseStack"

# 4. ComputeStack
echo "Deploying ComputeStack using compute.yaml"
aws cloudformation deploy \
    --stack-name ComputeStack \
    --template-file cloudformation/compute.yaml \
    --parameter-overrides \
        VPCId=$VPC_ID \
        PublicSubnet1=$PUBLIC_SUBNET_1 \
        PublicSubnet2=$PUBLIC_SUBNET_2 \
    --capabilities CAPABILITY_NAMED_IAM

wait_for_stack "ComputeStack"

# Get Compute outputs
LOAD_BALANCER_NAME=$(aws cloudformation describe-stacks \
    --stack-name ComputeStack \
    --query 'Stacks[0].Outputs[?OutputKey==`ApplicationLoadBalancerName`].OutputValue' \
    --output text | cut -d'/' -f3)

AUTO_SCALING_GROUP=$(aws cloudformation describe-stacks \
    --stack-name ComputeStack \
    --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupId`].OutputValue' \
    --output text)

echo "Compute outputs:"
echo "Load Balancer Name: $LOAD_BALANCER_NAME"
echo "Auto Scaling Group: $AUTO_SCALING_GROUP"

# 5. MonitoringStack
echo "Deploying MonitoringStack using monitoring.yaml"
aws cloudformation deploy \
    --stack-name MonitoringStack \
    --template-file cloudformation/monitoring.yaml \
    --parameter-overrides \
        LoadBalancerName=$LOAD_BALANCER_NAME \
        AutoScalingGroupName=$AUTO_SCALING_GROUP \
    --capabilities CAPABILITY_NAMED_IAM

wait_for_stack "MonitoringStack"

# 6. CICDStack
echo "Deploying CICDStack using cicd.yaml"
aws cloudformation deploy \
    --stack-name CICDStack \
    --template-file cloudformation/cicd.yaml \
    --parameter-overrides \
        GitHubOwner=guirgsilva \
        GitHubRepo=viewpost \
        GitHubBranch=main \
        GitHubTokenSecretName=github/aws-token \
    --capabilities CAPABILITY_NAMED_IAM

wait_for_stack "CICDStack"

echo "Infrastructure deployment completed successfully!"

# Print final deployment summary
echo "
Deployment Summary:
------------------
VPC ID: $VPC_ID
Load Balancer Name: $LOAD_BALANCER_NAME
Auto Scaling Group: $AUTO_SCALING_GROUP

Stack Status:
------------"
for stack in "NetworkStack" "StorageStack" "DatabaseStack" "ComputeStack" "MonitoringStack" "CICDStack"; do
    STATUS=$(aws cloudformation describe-stacks --stack-name $stack --query "Stacks[0].StackStatus" --output text)
    echo "$stack: $STATUS"
done