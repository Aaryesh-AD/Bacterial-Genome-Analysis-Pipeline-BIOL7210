/**
    This process uses SPAdes for genome assembly.
    It takes paired-end reads as input and produces a contig file as output.
    The process is designed to run in a temporary directory to avoid issues with path names. (had to do it, since there was a problem with spaces in the path names in my tests)
    The SPAdes assembler is run in isolate mode, which is optimized for bacterial genomes.
*/
process SPADES {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(read1), path(read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_contigs.fasta")
    
    script:
    """
    # Create a temporary directory for SPAdes output
    # This avoids issues with path names containing spaces or special characters
    TMPDIR=\$(mktemp -d -p /tmp spades_XXXXXX)
    
    # Execute SPAdes assembler in isolate mode (optimized for bacterial genomes)
    # Forward and reverse reads are provided along with output directory
    # Resource allocation is managed through task.cpus and task.memory
    spades.py \
        --isolate \
        -1 ${read1} \
        -2 ${read2} \
        -o \$TMPDIR \
        -t ${task.cpus} \
        -m ${task.memory.toGiga()}
    
    # Copy the assembled contigs with a sample-specific filename
    cp \$TMPDIR/contigs.fasta ${sample_id}_contigs.fasta
    
    # Remove temporary directory to free disk space
    rm -rf \$TMPDIR
    """
}

/**
    Workflow: SPADES_WF
    This workflow wraps the SPADES process, allowing it to be used as a modular component in larger workflows.
    It takes paired-end reads as input and outputs the assembled contigs.
*/
workflow SPADES_WF {
    take: reads
    main:
        SPADES(reads)
    emit:
        SPADES.out
}
