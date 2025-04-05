process SPADES {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(read1), path(read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_contigs.fasta")
    
    script:
    """
    # Create a temporary directory in /tmp (which never has spaces)
    TMPDIR=\$(mktemp -d -p /tmp spades_XXXXXX)
    
    # Run SPAdes with temp directory
    spades.py \
        --isolate \
        -1 ${read1} \
        -2 ${read2} \
        -o \$TMPDIR \
        -t ${task.cpus} \
        -m ${task.memory.toGiga()}
    
    # Copy results to working directory
    cp \$TMPDIR/contigs.fasta ${sample_id}_contigs.fasta
    
    # Clean up
    rm -rf \$TMPDIR
    """
}

workflow SPADES_WF {
    take: reads
    main:
        SPADES(reads)
    emit:
        SPADES.out
}