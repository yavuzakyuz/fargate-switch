#!/bin/bash

# usage
# ./script.sh <cluster-name> <service-name> <task-family>
# ./script.sh my-cluster my-service my-task-family
 
# needed arguments
CLUSTER_NAME=$1
SERVICE_NAME=$2
TASK_FAMILY=$3
 

# fetch current task definition
CURRENT_TASK_DEFINITION=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].taskDefinition" --output text)
# print current task definition
CURRENT_REVISION=$(echo $CURRENT_TASK_DEFINITION | cut -d: -f2)
# calculate previous revision
PREVIOUS_REVISION=$((CURRENT_REVISION-1))
#find previous task definition arn
PREVIOUS_TASK_DEFINITION_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --status ACTIVE --query "taskDefinitionArns[$PREVIOUS_REVISION]" --output text)
# print previous task definition arn
echo "Current Task Definition: $CURRENT_TASK_DEFINITION"
# update service with previous task definition
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $PREVIOUS_TASK_DEFINITION_ARN
 
