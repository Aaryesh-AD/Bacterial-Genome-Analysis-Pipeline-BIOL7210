/**
    * Module to retrieve paired-end reads from SRA using fasterq-dump
    * This module fetches paired-end reads from the SRA database using the fasterq-dump tool.
    * It handles the retrieval, compression, and integrity check of the FASTQ files.
*/
process GET_SRR {
    tag "$srr_id"
    
    input:
    val(srr_id)
    
    output:
    tuple val(srr_id), path("${srr_id}_1.fastq.gz"), path("${srr_id}_2.fastq.gz"), emit: reads
    
    // The output is a tuple containing the SRR ID and the paths to the compressed FASTQ files
    // The emit directive allows for the output to be used in downstream processes
    script:
    """
    # Retrieve SRA data and extract paired-end reads
    # The split-files option separates paired-end read files
    # Utilizing available CPU threads for optimal performance
    fasterq-dump \
        --split-files \
        --threads ${task.cpus} \
        --outdir ./ \
        ${srr_id}
    
    # Compress FASTQ files to reduce storage requirements
    # Standard compression for next-generation sequencing data
    gzip -f ${srr_id}_1.fastq
    gzip -f ${srr_id}_2.fastq
    
    # Verify file integrity before proceeding
    # Ensures both paired-end files exist and contain data
    if [ ! -s "${srr_id}_1.fastq.gz" ] || [ ! -s "${srr_id}_2.fastq.gz" ]; then
        echo "Error: One or both fastq files are empty or don't exist"
        exit 1
    fi
    """
}

// Workflow to handle the retrieval of paired-end reads from SRA
// This workflow takes a channel of SRR identifiers and processes them using the GET_SRR process
workflow GET_SRR_WF {
    take:
    srr_ids // Channel of SRR identifiers to process
    
    main:
    GET_SRR(srr_ids)
    
    emit:
    reads = GET_SRR.out.reads // Output channel containing processed paired-end reads
}