process GET_SRR {
    tag "$srr_id"
    
    input:
    val(srr_id)
    
    output:
    tuple val(srr_id), path("${srr_id}_1.fastq.gz"), path("${srr_id}_2.fastq.gz"), emit: reads
    
    script:
    """
    # Download and extract in one step with fasterq-dump
    fasterq-dump \
        --split-files \
        --threads ${task.cpus} \
        --outdir ./ \
        ${srr_id}
    
    # Compress the fastq files
    gzip -f ${srr_id}_1.fastq
    gzip -f ${srr_id}_2.fastq
    
    # Check if files exist and have content
    if [ ! -s "${srr_id}_1.fastq.gz" ] || [ ! -s "${srr_id}_2.fastq.gz" ]; then
        echo "Error: One or both fastq files are empty or don't exist"
        exit 1
    fi
    """
}

workflow GET_SRR_WF {
    take:
    srr_ids // Channel of SRR IDs
    
    main:
    GET_SRR(srr_ids)
    
    emit:
    reads = GET_SRR.out.reads
}