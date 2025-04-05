nextflow.enable.dsl=2

// Import processes from modules
include { FASTP_WF as FASTP } from '../modules/fastp'
include { QUAST_WF as QUAST } from '../modules/quast'
include { MULTIQC_WF as MULTIQC } from '../modules/multiqc'

// Quality Control and Profiling Subworkflow
workflow QUALITY_PROFILE {
    take:
        reads       // Input channel: [sample_id, read1, read2]
        assemblies  // Input channel: [sample_id, contigs]
        genes       // Input channel: [sample_id, faa, gff, stats]
        domains     // Input channel: [sample_id, tbl, domtbl]
        homology    // Input channel: [sample_id, tsv]
    
    main:
        // Quality control with fastp
        FASTP(reads)
        
        // Assembly quality assessment with QUAST
        QUAST(assemblies)
        
        // Collect all outputs for MultiQC
        // Make sure we're using the correct output names from our modules
        multiqc_inputs = Channel.empty()
            // Use the correct output channel from FASTP (e.g., 'html' or 'report')
            .mix(FASTP.out.html)  // Change this to match what your FASTP module actually outputs
            .mix(QUAST.out.map { it -> it[1] })
            .mix(genes.map { sample_id, faa, gff, stats -> stats })
            .mix(domains.map { sample_id, tbl, domtbl -> tbl })
            .mix(homology.map { sample_id, tsv -> tsv })
            .collect()
        
        // Generate MultiQC report
        MULTIQC(multiqc_inputs)
    
    emit:
        qc_reads = FASTP.out.reads
        qc_report = MULTIQC.out.report
}