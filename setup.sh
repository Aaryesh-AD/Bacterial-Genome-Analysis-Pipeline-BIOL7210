#!/bin/bash
# filepath: ./setup.sh
# -*- mode: bash -*-

# Setup script for Functional Gene Discovery Pipeline
# This script preloads all required Docker containers for the pipeline

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi
}

pull_containers() {
    log "Starting container image downloads..."
    
    # Quality control and assembly
    docker pull staphb/fastp:0.23.2
    docker pull staphb/spades:3.15.5
    docker pull staphb/quast:5.2.0
    
    # Annotation tools
    docker pull quay.io/biocontainers/prodigal:2.6.3--h031d066_6
    docker pull quay.io/biocontainers/hmmer:3.3.2--h1b792b2_1
    docker pull quay.io/biocontainers/diamond:2.1.6--h5b5514e_0
    
    # Report generation
    docker pull quay.io/biocontainers/multiqc:1.14--pyhdfd78af_0
    
    # SRA tools (for remote data access)
    docker pull quay.io/biocontainers/sra-tools:3.0.3--h87f3376_0
    
    log "All container images downloaded successfully"
}

main() {
    log "Setting up pipeline environment"
    check_docker
    pull_containers
    log "Setup complete. The pipeline is ready to run."
}

# Execute main function
main