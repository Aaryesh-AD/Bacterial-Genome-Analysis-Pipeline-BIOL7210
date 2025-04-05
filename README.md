# Bacterial Genome Analysis Pipeline - BIOL7210

<div align="center">
  <img src="https://raw.githubusercontent.com/nextflow-io/trademark/master/nextflow-logo-bg-dark.png" alt="Nextflow Logo" width="200"/>
</div>
<br>

<div align="center">
  <a href="https://www.nextflow.io/"><img src="https://img.shields.io/badge/nextflow-DSL2-brightgreen?style=flat-square&logo=nextflow" alt="Nextflow"></a>
  <a href="#"><img src="https://img.shields.io/badge/container-docker-blue?logo=docker&style=flat-square" alt="Dockerized"></a>
  <img src="https://img.shields.io/github/repo-size/Aaryesh-AD/Bacterial-Genome-Analysis-Pipeline-BIOL7210" alt="GitHub Repo size">
  <img src="https://img.shields.io/github/last-commit/Aaryesh-AD/Bacterial-Genome-Analysis-Pipeline-BIOL7210" alt="GitHub last commit">
</div>

---

A robust Nextflow pipeline for simple bacterial genome assembly, annotation, and functional gene discovery, developed as part of Georgia Tech's BIOL7210 Computational Genomics Course.

## Overview

This pipeline implements a modular workflow for bacterial genomics that includes quality control, genome assembly, gene prediction, and functional annotation. The pipeline is designed to handle both local sequence data and automated SRA data retrieval.

## Features

- Quality control and adapter trimming with Fastp
- De novo genome assembly with SPAdes
- Gene prediction using Prodigal
- Functional annotation with:
  - Protein domain identification (HMMER/Pfam)
  - Homology-based analysis (DIAMOND)
- Assembly quality assessment with QUAST
- Comprehensive reporting with MultiQC
- Support for local FASTQ files or direct SRA accession processing

## Pipeline Diagram

```
                ┌─────────────┐
                │ Input Reads │
                └──────┬──────┘
                       │
         ┌─────────────┴────────────┐
         │                          │
┌────────▼─────────┐      ┌─────────▼─────────┐
│    Local FASTQ   │      │   SRA Download    │
└────────┬─────────┘      └─────────┬─────────┘
         │                          │
         └──────────┬───────────────┘
                    │
         ┌──────────▼───────────┐
         │ Assembly Annotation  │
         └──────────┬───────────┘
                    │
     ┌──────────────┼──────────────┐
     │              │              │
┌────▼─────┐   ┌────▼─────┐   ┌────▼─────┐
│  SPAdes  │   │ Prodigal │   │  Domain  │
│ Assembly │   │   Gene   │   │ Analysis │
└────┬─────┘   │ Finding  │   └────┬─────┘
     │         └────┬─────┘        │
     │              │              │
     └──────────────┼──────────────┘
                    │
           ┌────────▼────────┐
           │ Quality Profile │
           └────────┬────────┘
                    │
     ┌──────────────┼──────────────┐
     │              │              │
┌────▼─────┐   ┌────▼─────┐   ┌────▼─────┐
│  FASTP   │   │   QUAST  │   │  MultiQC │
│    QC    │   │ Assembly │   │  Report  │
│          │   │   QC     │   │          │
└──────────┘   └──────────┘   └──────────┘
```

## Requirements

- [Nextflow](https://www.nextflow.io/) (v22.10.0 or later)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)
- Basic computational resources:
  - Minimum: 8 CPU cores, 16GB RAM
  - Recommended: 16+ CPU cores, 32GB+ RAM

### Test System Info

```bash
OS       : Ubuntu 20.04.6 LTS (WSL2 on Windows 10 x86_64)
Kernel   : 5.15.167.4-microsoft-standard-WSL2

CPU      : AMD Ryzen 7 7735HS with Radeon Graphics (16 cores @ 3.19GHz)
RAM      : 32 GB (Used: ~4.1 GB during test run)
Nextflow : v24.10.5
Java     : OpenJDK 22 (via Conda)
```

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/Aaryesh-AD/Bacterial-Genome-Analysis-Pipeline-BIOL7210.git
cd Bacterial-Genome-Analysis-Pipeline-BIOL7210
```

2. Set up the environment:
```bash
# Setup Environment and Dependencies

# Create a Conda environment with required dependencies
conda env create -f environment.yml

# Activate the environment
conda activate nf-bac-genomics

# Make the setup script executable
chmod +x setup.sh

# Run the setup script to preload Docker images
./setup.sh
```


3. Run the pipeline with test data:
```bash
nextflow run main.nf -profile docker
```

4. Process SRA accessions directly:
```bash
nextflow run main.nf -profile docker --use_sra --sra_ids "SRR10971381,SRR10971382"
```

### Docker Container (Optional) - May cause issues

You can also run the entire pipeline within a Docker container:

1. Build the Docker image:
```bash
docker build -t biol7210-pipeline .
```

2. Run the pipeline with test data:
```bash
# Create a directory for results
mkdir -p results

# Run the pipeline with test data, mounting the results directory
docker run -v $(pwd)/results:/pipeline/results biol7210-pipeline
```

3. Run with SRA data:
```bash
docker run -v $(pwd)/results:/pipeline/results biol7210-pipeline --use_sra --sra_ids "SRR10971381"
```

4. Get help:
```bash
docker run biol7210-pipeline help
```

> [!CAUTION]
> This containerized approach includes Nextflow itself. Since the pipeline uses Docker for individual processes, this creates a Docker-in-Docker scenario which may require additional permissions. For simpler deployments, we recommend installing Nextflow directly on your system and using the standard execution commands.


## Input

The pipeline accepts two types of input:

### Local FASTQ Files

By default, the pipeline looks for paired-end reads in the `test_data` directory:

```
test_data/
├── sample1_R1.fastq.gz
└── sample1_R2.fastq.gz
```
### Test Data

The included test data in the `test_data/` directory contains downsampled paired-end reads from *Klebsiella pneumoniae* (SRA accession: SRR32935048). The reads have been downsampled to approximately 75% of the original dataset (~1,400,000 reads) using seqtk:

```bash
# Command used for downsampling (for reference)
seqtk sample -s200 SRR32935048_1.fastq.gz 0.75 > klebsiella_R1.fastq
seqtk sample -s200 SRR32935048_2.fastq.gz 0.75 > klebsiella_R2.fastq
gzip klebsiella_R1.fastq klebsiella_R2.fastq
```
This downsampled dataset is provided solely for testing the pipeline functionality and should not be used for actual research purposes. For real analyses, please use full datasets or your own sequencing data.

To run the pipeline with the full Klebsiella pneumoniae dataset, you can use:
```bash
nextflow run main.nf -profile docker --use_sra --sra_ids "SRR32935048"
```
The pipeline will automatically download the full dataset from SRA.

You can specify a different location using the `--reads` parameter:

```bash
nextflow run main.nf --reads "/path/to/data/*_R{1,2}.fastq.gz"
```

### SRA Accessions

To download and process data directly from NCBI's Sequence Read Archive:

```bash
nextflow run main.nf --use_sra --sra_ids "SRR10971381,SRR10971382"
```

## Output

Results are organized in the `results` directory (configurable with `--outdir`):

```
results/
├── fastp/                 # Quality-filtered reads and QC reports
├── spades/                # Assembled genomes
├── quast/                 # Assembly quality metrics
├── prodigal/              # Predicted genes and proteins
├── hmmscan/               # Protein domain annotation
├── diamond/               # Homology search results
├── multiqc/               # Consolidated QC report
└── sra_data/              # Downloaded SRA data (if applicable)
```

## Configuration

The pipeline behavior can be customized through various parameters:

```bash
# Change computational resources
nextflow run main.nf --cpus 16 --memory '32 GB'

# Specify custom databases
nextflow run main.nf --pfam_db '/path/to/pfam/db' --nr_db '/path/to/protein/db'

# Adjust tool parameters
nextflow run main.nf --hmmscan_evalue 1e-10 --diamond_evalue 1e-10
```

See the Parameters section for a complete list of options.

## Execution Environments

The pipeline supports multiple execution environments through profiles:

```bash
# Local execution with Docker
nextflow run main.nf -profile docker

# Execution with Singularity
nextflow run main.nf -profile singularity

# AWS Batch execution
nextflow run main.nf -profile awsbatch
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--reads` | Pattern for input read files | `test_data/*_R{1,2}.fastq.gz` |
| `--use_sra` | Enable SRA data download | `false` |
| `--sra_ids` | Comma-separated list of SRA accession numbers | `""` |
| `--outdir` | Directory for pipeline results | `results` |
| `--pfam_db` | Path to Pfam HMM database | `false` (auto-download) |
| `--nr_db` | Path to protein reference database for DIAMOND | `false` (auto-download) |
| `--hmmscan_evalue` | E-value threshold for domain detection | `1e-5` |
| `--diamond_evalue` | E-value threshold for homology search | `1e-5` |
| `--cpus` | Number of CPU cores | `8` |
| `--memory` | Maximum memory allocation | `16 GB` |
| `--max_time` | Maximum execution time per task | `48.h` |

## Module Details

### Quality Control

- **FASTP**: Adapter trimming, quality filtering, and read QC
- **QUAST**: Assembly quality assessment
- **MultiQC**: Consolidated reporting

### Assembly and Annotation

- **GET_SRR**: SRA data retrieval (when using `--use_sra`)
- **SPADES**: De novo genome assembly
- **PRODIGAL**: Ab initio gene prediction
- **HMMSCAN**: Protein domain identification
- **DIAMOND**: Homology-based annotation

## Troubleshooting

### Common Issues

1. **Container errors**: If container execution fails, ensure Docker/Singularity is properly installed and run setup.sh to preload containers.

2. **Resource limitations**: For large genome assemblies, increase available resources:
   ```bash
   nextflow run main.nf --cpus 16 --memory '32 GB'
   ```

3. **Path issues**: Nextflow may have issues with paths containing spaces. Use paths without spaces or special characters.

4. **SRA download failures**: Ensure internet connectivity and sufficient disk space. For persistent issues, download SRA data manually and use as local input.

### Resuming Failed Runs

To resume a failed run from the last successful task:

```bash
nextflow run main.nf -resume
```

## Development

This pipeline was developed for BIOL7210 Computational Genomics to demonstrate Nextflow-based workflow development for bacterial genomics. The modular structure facilitates expansion and customization.

## Tools Used

- [Nextflow](https://www.nextflow.io/)
- [SPAdes](https://cab.spbu.ru/software/spades/)
- [Fastp](https://github.com/OpenGene/fastp)
- [Prodigal](https://github.com/hyattpd/Prodigal)
- [HMMER](http://hmmer.org/)
- [DIAMOND](https://github.com/bbuchfink/diamond)
- [QUAST](http://quast.sourceforge.net/quast)
- [MultiQC](https://multiqc.info/)
- [SRA-tools](https://github.com/ncbi/sra-tools)

## Acknowledgements

This pipeline was developed as part of the **Georgia Tech's BIOL7210 - Computational Genomics** course. Special thanks to the **Nextflow community** for their excellent documentation and examples, which greatly supported this work. 

I would also like to thank **Dr. Christopher Gulvik**, the instructor of the course, for his guidance and support throughout the coursework.

## Contact

For questions or issues specific to the repository, please submit an issue.

For collaboration inquiries or general questions, feel free to reach out:

**[Aaryesh Deshpande](mailto:adeshpande334@gatech.edu)**  
MS Bioinformatics  
*adeshpande334*  

---

