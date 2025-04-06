/**
 * Read quality control and preprocessing using fastp
 *
 * This module performs adapter trimming, quality filtering, and other
 * preprocessing steps on paired-end sequencing reads.
 */
process FASTP {
    tag "$sample_id"
    publishDir "${params.outdir}/fastp", mode: "copy",
        saveAs: { filename ->
            if (filename.endsWith(".html")) "reports/${filename}"
            else if (filename.endsWith(".json")) "reports/${filename}"
            else params.save_trimmed_reads ? "trimmed/${filename}" : null
        }
    
    input:
    tuple val(sample_id), path(read1), path(read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_1.trimmed.fastq.gz"), path("${sample_id}_2.trimmed.fastq.gz"), emit: reads
    path("${sample_id}_fastp.html"), emit: html
    path("${sample_id}_fastp.json"), emit: json
    
    // Change the parameters as needed. 
    script:
    """
    # Run fastp with optimized parameters
    fastp \
        --in1 ${read1} \
        --in2 ${read2} \
        --out1 ${sample_id}_1.trimmed.fastq.gz \
        --out2 ${sample_id}_2.trimmed.fastq.gz \
        --detect_adapter_for_pe \
        --qualified_quality_phred ${params.fastp_qualified_quality} \
        --unqualified_percent_limit ${params.fastp_unqualified_percent_limit} \
        --cut_front \
        --cut_front_window_size ${params.fastp_cut_window_size} \
        --cut_front_mean_quality ${params.fastp_cut_mean_quality} \
        --cut_tail \
        --cut_tail_window_size ${params.fastp_cut_window_size} \
        --cut_tail_mean_quality ${params.fastp_cut_mean_quality} \
        --length_required ${params.fastp_min_length} \
        --html ${sample_id}_fastp.html \
        --json ${sample_id}_fastp.json \
        --thread ${task.cpus}
    """
}