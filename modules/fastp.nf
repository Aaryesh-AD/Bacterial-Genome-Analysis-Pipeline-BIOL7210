/**
 * Process FASTP
 * 
 * Performs quality control and adapter trimming on paired-end Illumina reads
 * using the Fastp tool. This process trims adapters, filters low quality reads,
 * and produces both trimmed fastq files and QC reports.
 */
process FASTP {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(read1), path(read2)  // Sample ID and paired-end read files
    
    output:
    tuple val(sample_id), path("${sample_id}_1.trimmed.fastq.gz"), path("${sample_id}_2.trimmed.fastq.gz"), emit: reads  // Trimmed read pairs
    path("${sample_id}_fastp.html"), emit: html  // HTML report
    path("${sample_id}_fastp.json"), emit: json  // JSON metrics file
    
    script:
    // Execute fastp with paired-end mode settings and auto-detection of adapters
    """
    fastp \
        --in1 ${read1} \
        --in2 ${read2} \
        --out1 ${sample_id}_1.trimmed.fastq.gz \
        --out2 ${sample_id}_2.trimmed.fastq.gz \
        --json ${sample_id}_fastp.json \
        --html ${sample_id}_fastp.html \
        --detect_adapter_for_pe \
        --thread ${task.cpus}
    """
}

/**
 * Workflow: FASTP_WF
 * 
 * A wrapper workflow around the FASTP process. This provides a modular
 * component that can be included in larger workflows. It takes paired
 * read files as input and outputs trimmed read files along with QC reports.
 */
workflow FASTP_WF {
    take: reads  // Input channel with paired-end reads
    
    main:
        FASTP(reads)  // Execute fastp on all input samples
    
    emit:
        reads = FASTP.out.reads  // Trimmed read pairs
        html = FASTP.out.html    // HTML reports
        json = FASTP.out.json    // JSON metrics files
}