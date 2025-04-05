nextflow.enable.dsl=2

// Import process modules for quality control and analysis
include { FASTP_WF as FASTP } from '../modules/fastp'
include { QUAST_WF as QUAST } from '../modules/quast'
include { MULTIQC_WF as MULTIQC } from '../modules/multiqc'

/**
 * Quality Control and Profiling Subworkflow
 * Performs read quality filtering, assembly evaluation, and generates comprehensive reports
 */
workflow QUALITY_PROFILE {
    take:
        reads       // Input channel: [sample_id, read1, read2] - Raw sequencing reads
        assemblies  // Input channel: [sample_id, contigs] - Assembled contigs
        genes       // Input channel: [sample_id, faa, gff, stats] - Gene prediction results
        domains     // Input channel: [sample_id, tbl, domtbl] - Protein domain analysis
        homology    // Input channel: [sample_id, tsv] - Homology search results
    
    main:
        // Quality control and trimming of input reads
        FASTP(reads)
        
        // Assembly quality assessment and metrics calculation
        QUAST(assemblies)
        
        // Aggregate quality metrics from all processes for comprehensive reporting
        // Each input is transformed to extract only the relevant files for MultiQC
        multiqc_inputs = Channel.empty()
            .mix(FASTP.out.html)  // QC reports from read processing
            .mix(QUAST.out.map { it -> it[1] })  // Assembly quality metrics
            .mix(genes.map { sample_id, faa, gff, stats -> stats })  // Gene statistics
            .mix(domains.map { sample_id, tbl, domtbl -> tbl })  // Domain analysis results
            .mix(homology.map { sample_id, tsv -> tsv })  // Homology search summaries
            .collect()  // Collect all files for a single MultiQC run
        
        // Generate consolidated quality report
        MULTIQC(multiqc_inputs)
    
    emit:
        qc_reads = FASTP.out.reads  // Quality-filtered reads for downstream analysis
        qc_report = MULTIQC.out.report  // Comprehensive QC report
}