#!/bin/bash

# Authenticate Docker client to AWS ECR
function aws_ecr_authentication {
    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_CONTAINER_REGISTRY_URL}
}
