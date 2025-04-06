nextflow.enable.dsl=2

// Import modular subworkflows
include { ASSEMBLY_AMR_WORKFLOW } from './subworkflows/assembly_amr_wf'

/**
 * Main workflow for bacterial genome analysis
 * This pipeline performs assembly, annotation, quality assessment, and functional profiling
 */
workflow {
    // Display pipeline information and configuration summary
    log.info """
==============================================================================

██████╗░██╗░█████╗░██╗░░░░░  ░░░░░░  ███████╗██████╗░░░███╗░░░█████╗░
██╔══██╗██║██╔══██╗██║░░░░░  ░░░░░░  ╚════██║╚════██╗░████║░░██╔══██╗
██████╦╝██║██║░░██║██║░░░░░  █████╗  ░░░░██╔╝░░███╔═╝██╔██║░░██║░░██║
██╔══██╗██║██║░░██║██║░░░░░  ╚════╝  ░░░██╔╝░██╔══╝░░╚═╝██║░░██║░░██║
██████╦╝██║╚█████╔╝███████╗  ░░░░░░  ░░██╔╝░░███████╗███████╗╚█████╔╝
╚═════╝░╚═╝░╚════╝░╚══════╝  ░░░░░░  ░░╚═╝░░░╚══════╝╚══════╝░╚════╝░

BACTERIAL GENOME ASSEMBLY & AMR ANALYSIS PIPELINE - Nexflow v${nextflow.version}
==============================================================================
Input: ${params.use_sra ? "SRA IDs: ${params.sra_ids}" : "Reads: ${params.reads}"}
Output dir: ${params.outdir}
==============================================================================
"""
    // Initialize the input channel based on the selected data source
    if (!params.use_sra) {
        // Process local FASTQ files when SRA mode is disabled
        Channel
            .fromFilePairs(params.reads, flat: true)
            .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
            .set { input_data }
        
        log.info " Using local FASTQ files: ${params.reads}"
    } else {
        // For SRA mode, we'll handle data fetching within the ASSEMBLY_AMR_WORKFLOW
        input_data = Channel.empty()
        
        log.info " Using SRA accessions: ${params.sra_ids}"
    }
    
    // Execute the streamlined assembly and AMR detection workflow
    ASSEMBLY_AMR_WORKFLOW(input_data)
}

// Display completion message
workflow.onComplete {
    log.info """
    Pipeline execution summary
    ---------------------------
    Completed at : ${workflow.complete}
    Duration     : ${workflow.duration}
    Success      : ${workflow.success}
    workDir      : ${workflow.workDir}
    exit status  : ${workflow.exitStatus}
    """
}

// Add this to main.nf after initial declarations
workflow.onError {
    log.error "Pipeline execution stopped with error: ${workflow.errorMessage}"
    log.info """
    =============================================
    TROUBLESHOOTING TIPS:
    
    1. Check container availability:
       Run ./verify_containers.sh to verify all required containers
    
    2. Check for spaces in paths:
       QUAST and other tools may have issues with spaces in paths
    
    3. Check input data:
       Ensure input data is properly formatted and accessible
    
    4. Memory/CPU issues:
       For large genomes, increase memory with --memory parameter
    
    For detailed logs, check .nextflow.log and process work directories
    =============================================
    """
}