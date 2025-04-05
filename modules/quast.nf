process QUAST {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}_quast")
    
    script:
    """
    # Create a temporary directory in /tmp (which never has spaces)
    TMPDIR=\$(mktemp -d -p /tmp quast_XXXXXX)
    
    # Run QUAST with temp directory
    quast.py ${contigs} \
        -o \$TMPDIR \
        --threads ${task.cpus} \
        --min-contig 200
    
    # Copy results to working directory
    cp -r \$TMPDIR ${sample_id}_quast
    
    # Clean up
    rm -rf \$TMPDIR
    """
}

workflow QUAST_WF {
    take: assemblies
    main:
        QUAST(assemblies)
    emit:
        QUAST.out
}