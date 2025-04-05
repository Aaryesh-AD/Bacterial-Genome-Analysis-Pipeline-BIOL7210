/*
 * QUAST module for assembly quality assessment
 *
 * This module runs QUAST to evaluate assembly quality metrics for the
 * provided contigs. It generates reports on metrics such as N50, total
 * length, number of contigs, and other quality indicators.
 */

process QUAST {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}_quast")
    
    script:
    """
    # Create a temporary directory in /tmp to avoid path issues
    TMPDIR=\$(mktemp -d -p /tmp quast_XXXXXX)
    
    # Run QUAST analysis on the assembly with specified parameters
    quast.py ${contigs} \
        -o \$TMPDIR \
        --threads ${task.cpus} \
        --min-contig 200
    
    # Copy the analysis results to a named output directory
    cp -r \$TMPDIR ${sample_id}_quast
    
    # Remove the temporary directory after use
    rm -rf \$TMPDIR
    """
}

/*
 * QUAST workflow component
 * Takes assembly files as input and performs quality assessment
 */
workflow QUAST_WF {
    take: assemblies
    main:
        QUAST(assemblies)
    emit:
        QUAST.out
}