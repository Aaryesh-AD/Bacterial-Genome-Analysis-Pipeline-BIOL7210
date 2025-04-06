#!/bin/bash
# filepath: ./verify_containers.sh
# -*- mode: bash -*-

# Setup script for Functional Gene Discovery Pipeline
# This script verifies that all required Docker containers are available for the pipeline
# It checks if Docker is installed, if the daemon is running, and if the required containers can be pulled

set -e

echo "Verifying Docker container images required for the pipeline..."

# Define the list of required Docker containers with correct repositories and tags
CONTAINERS=(
    "staphb/fastp:0.23.2" 
    "staphb/spades:3.15.5"
    "staphb/quast:5.2.0"
    "biocontainers/prodigal:v2.6.3_cv1"
    "ncbi/amr:3.11.12"
    "staphb/sra-tools:3.0.3"
)

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in your PATH"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running or you don't have permission to use it"
    echo "Try running: sudo systemctl start docker"
    echo "Or add your user to the docker group: sudo usermod -aG docker $USER && newgrp docker"
    exit 1
fi

# Check each container
echo "Checking container images..."
for container in "${CONTAINERS[@]}"; do
    echo -n "  $container: "
    if docker pull $container &> /dev/null; then
        echo "✓ OK"
    else
        echo "✗ FAILED"
        echo "    Error pulling $container - check if the repository and tag exist"
        echo "    You may need to run: docker pull $container"
        exit 1
    fi
done

echo "All required container images verified successfully!"
exit 0