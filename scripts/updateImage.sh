#!/bin/bash

# Prompt user for input
read -e -p "Enter AWS Region: " AWS_REGION
read -e -p "Enter ECS Cluster Name: " ECS_CLUSTER_NAME
read -e -p "Enter ECS Service Name: " ECS_SERVICE_NAME
read -e -p "Enter Full Image Name: " FULL_IMAGE

echo "Updating Image for:"
echo "AWS Region: $AWS_REGION"
echo "ECS Cluster Name: $ECS_CLUSTER_NAME"
echo "ECS Service Name: $ECS_SERVICE_NAME"
echo "Full Image: $FULL_IMAGE"

TASK_FAMILY="$ECS_SERVICE_NAME"

# public.ecr.aws/docker/library/httpd:latest

# Set AWS region
export AWS_DEFAULT_REGION=$AWS_REGION
echo "Setting AWS region to: $AWS_DEFAULT_REGION"

# Retrieve current task definitions
CURRENT_TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --region "$AWS_DEFAULT_REGION" --output json)

# Extract container definitions and relevant parameters
CONTAINER_MEMORY=$(echo $CURRENT_TASK_DEFINITION | aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --region "$AWS_DEFAULT_REGION" --query "taskDefinition.containerDefinitions[0].memory" --output text)
CONTAINER_CPU=$(echo $CURRENT_TASK_DEFINITION | aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --region "$AWS_DEFAULT_REGION" --query "taskDefinition.containerDefinitions[0].cpu" --output text)

CONTAINER_DEF=$(echo $CURRENT_TASK_DEFINITION | aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --region "$AWS_DEFAULT_REGION" --query "taskDefinition.containerDefinitions" --output json)

# Replace the image in container description
CONTAINER_DEF_UPDATED=$(echo $CONTAINER_DEF | sed "s|\"image\": \"[^\"]*\"|\"image\": \"$FULL_IMAGE\"|")

# Fargate mandates cpu and mem definition
CPU_VALUE="$CONTAINER_CPU" 
MEMORY_VALUE=$CONTAINER_MEMORY 
NETWORK_MODE="awsvpc"

# Register the new task definition with Fargate compatibility
aws ecs register-task-definition --family "$TASK_FAMILY" \
--requires-compatibilities "FARGATE" \
--network-mode "$NETWORK_MODE" \
--cpu "$CPU_VALUE" \
--memory "$MEMORY_VALUE" \
--container-definitions "$CONTAINER_DEF_UPDATED" &

# Update the ECS service to use the latest revision of the task definition
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --task-definition ${TASK_FAMILY} --force-new-deployment

echo "Updated $ECS_SERVICE_NAME to use $FULL_IMAGE"