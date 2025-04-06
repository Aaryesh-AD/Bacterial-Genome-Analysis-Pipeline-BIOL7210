#!/bin/bash
# filepath: ./setup.sh
# -*- mode: bash -*-

# Setup script for Functional Gene Discovery Pipeline
# This script preloads all required Docker containers for the pipeline

set -e

log() {
    echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')]\033[0m $1"
}

error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
    exit 1
}

warn() {
    echo -e "\033[0;33m[WARNING]\033[0m $1"
}

check_dependencies() {
    log "Checking required dependencies..."
    
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH. Please install Docker."
    fi
    log "✓ Docker is available"
    
    # Check for Nextflow
    if ! command -v nextflow &> /dev/null; then
        warn "Nextflow is not installed or not in PATH."
        read -p "Would you like to install Nextflow? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing Nextflow..."
            curl -s https://get.nextflow.io | bash
            chmod +x nextflow
            mv nextflow /usr/local/bin/ 2>/dev/null || sudo mv nextflow /usr/local/bin/
        else
            warn "Skipping Nextflow installation. You will need to install it manually."
        fi
    else
        log "✓ Nextflow is available ($(nextflow -v))"
    fi
    
    # Check for test data
    if [ ! -d "test_data" ]; then
        warn "Test data directory not found."
        read -p "Would you like to create test data? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p test_data
            log "Created test_data directory. Please add FASTQ files."
        fi
    else
        log "✓ Test data directory exists"
    fi
}

pull_containers() {
    log "Downloading Docker containers..."
    
    # Create an array of required containers
    containers=(
        "quay.io/biocontainers/sra-tools:3.0.3--h87f3376_0"
        "staphb/fastp:0.23.2"
        "staphb/spades:3.15.5"
        "staphb/quast:5.2.0"
        "quay.io/biocontainers/prodigal:2.6.3--h031d066_6"
        "staphb/ncbi-amrfinderplus:4.0.19-2024-12-18.1"
    )
    
    # Pull each container with progress indicator
    total=${#containers[@]}
    current=0
    
    for container in "${containers[@]}"; do
        current=$((current+1))
        log "[$current/$total] Pulling $container"
        docker pull $container
    done
    
    log "All containers downloaded successfully"
}

# Update this function in your setup.sh
verify_containers() {
    log "Verifying containers..."
    
    # Test AMRFinderPlus
    log "Testing AMRFinderPlus container..."
    docker run --rm staphb/ncbi-amrfinderplus:4.0.19-2024-12-18.1 amrfinder --version
    
    # Test Prodigal
    log "Testing Prodigal container..."
    docker run --rm quay.io/biocontainers/prodigal:2.6.3--h031d066_6 prodigal -v
    
    log "All containers verified"
}

create_test_config() {
    log "Creating test configuration file..."
    
    cat > test_params.config <<EOL
params {
    // Use test profile settings
    reads = "test_data/*_R{1,2}.fastq.gz"
    outdir = "test_results"
    memory = '4 GB'
    cpus = 2
    
    // Faster testing
    fastp_min_length = 30
    spades_mode = "isolate"
    quast_min_contig = 100
}
EOL
    
    log "Created test_params.config - use with: nextflow run main.nf -c test_params.config"
}

main() {
    log "Setting up Bacterial AMR Pipeline"
    check_dependencies
    pull_containers
    verify_containers
    create_test_config
    
    log "=========================================================="
    log "Setup complete! You can now run the pipeline with:"
    log "  nextflow run main.nf -profile docker"
    log ""
    log "For a quick test run:"
    log "  nextflow run main.nf -profile docker -c test_params.config"
    log "=========================================================="
}

# Execute main function
main