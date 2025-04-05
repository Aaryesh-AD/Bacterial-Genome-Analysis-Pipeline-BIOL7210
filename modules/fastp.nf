process FASTP {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(read1), path(read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_1.trimmed.fastq.gz"), path("${sample_id}_2.trimmed.fastq.gz"), emit: reads
    path("${sample_id}_fastp.html"), emit: html
    path("${sample_id}_fastp.json"), emit: json
    
    script:
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

workflow FASTP_WF {
    take: reads
    main:
        FASTP(reads)
    emit:
        reads = FASTP.out.reads
        html = FASTP.out.html
        json = FASTP.out.json
}