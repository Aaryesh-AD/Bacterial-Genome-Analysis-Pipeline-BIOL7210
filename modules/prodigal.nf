process PRODIGAL {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}.faa"), path("${sample_id}.gff"), path("${sample_id}_prodigal.stats")
    
    script:
    """
    # Run Prodigal for gene prediction
    prodigal \
        -i ${contigs} \
        -a ${sample_id}.faa \
        -f gff \
        -o ${sample_id}.gff \
        -p meta \
        -q > ${sample_id}_prodigal.stats
    
    # Generate additional stats
    echo "# Predicted genes: \$(grep -c ">" ${sample_id}.faa)" >> ${sample_id}_prodigal.stats
    """
}

workflow PRODIGAL_WF {
    take: assemblies
    main:
        PRODIGAL(assemblies)
    emit:
        PRODIGAL.out
}