#!/bin/bash
# filepath: ./run.sh
# -*- mode: bash -*-

# Run script for Bacterial AMR Pipeline
# Enhanced version with more options and better error handling

# Make the script executable
chmod +x run.sh

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display header
show_header() {
    echo -e "${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          BIOL - 7210  Bacterial AMR Pipeline           ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to display help message
show_help() {
    show_header
    echo -e "${BOLD}USAGE:${NC}"
    echo -e "  ./run.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo -e "  ${GREEN}-r, --resume${NC}         Resume the previous pipeline run"
    echo -e "  ${GREEN}-c, --clean${NC}          Clean work directory before running"
    echo -e "  ${GREEN}-o, --outdir${NC} DIR     Set custom output directory"
    echo -e "  ${GREEN}-p, --profile${NC} PROF   Set execution profile (default: docker)"
    echo -e "  ${GREEN}-s, --sra${NC} ACCESSION  Run with SRA data (comma-separated accessions)"
    echo -e "  ${GREEN}-i, --reads${NC} PATTERN  Set custom input reads pattern"
    echo -e "  ${GREEN}-t, --threads${NC} N      Set number of CPU threads to use"
    echo -e "  ${GREEN}-m, --memory${NC} MEM     Set maximum memory (e.g., '16 GB')"
    echo -e "  ${GREEN}-h, --help${NC}           Show this help message"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  ./run.sh --resume                 # Resume the previous run"
    echo -e "  ./run.sh --clean --threads 8      # Clean work dir and use 8 threads"
    echo -e "  ./run.sh --sra SRR10971381        # Process an SRA accession"
    echo -e "  ./run.sh --reads \"data/*_R{1,2}.fq.gz\" # Set custom read pattern"
    echo ""
}

# Check if Nextflow is installed
check_nextflow() {
    if ! command -v nextflow &> /dev/null; then
        echo -e "${RED}Error: Nextflow is not installed or not in PATH${NC}"
        echo "Please install Nextflow first: https://www.nextflow.io/docs/latest/getstarted.html"
        exit 1
    fi
}

# Default values
RESUME=""
CLEAN=false
PROFILE="docker"
OUTDIR=""
SRA_IDS=""
READS=""
THREADS=""
MEMORY=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--resume)
            RESUME="-resume"
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -o|--outdir)
            OUTDIR="--outdir $2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -s|--sra)
            SRA_IDS="--use_sra --sra_ids \"$2\""
            shift 2
            ;;
        -i|--reads)
            READS="--reads \"$2\""
            shift 2
            ;;
        -t|--threads)
            THREADS="--cpus $2"
            shift 2
            ;;
        -m|--memory)
            MEMORY="--memory \"$2\""
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Check for Nextflow
check_nextflow

# Display header
show_header

# Clean work directory if requested
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Cleaning work directory...${NC}"
    rm -rf work .nextflow* results
    echo "Done."
fi

# Prepare command
CMD="nextflow run main.nf -profile $PROFILE $RESUME $OUTDIR $SRA_IDS $READS $THREADS $MEMORY"

# Display and run the command
echo -e "${YELLOW}Executing:${NC} $CMD"
echo -e "${YELLOW}Starting pipeline...${NC}"
echo ""

# Run the pipeline
eval $CMD

# Check exit status
STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Pipeline execution completed successfully!${NC}"
    echo -e "Results are available in the output directory."
else
    echo ""
    echo -e "${RED}Pipeline execution failed with status code: $STATUS${NC}"
    echo -e "Check the logs for details."
fi

exit $STATUS