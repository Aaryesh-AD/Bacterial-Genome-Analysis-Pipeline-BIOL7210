nextflow.enable.dsl=2

// Import modular subworkflows
include { ASSEMBLY_ANNOTATION } from './subworkflows/assembly_and_annotation'
include { QUALITY_PROFILE } from './subworkflows/quality_and_profile'

/**
 * Main workflow for bacterial genome analysis
 * This pipeline performs assembly, annotation, quality assessment, and functional profiling
 */
workflow {
    // Display pipeline information and configuration summary
    log.info """
==============================================================================
BIOL7210 FUNCTIONAL GENE DISCOVERY WORKFLOW - Nexflow v${nextflow.version}
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
    } else {
        // For SRA mode, we'll handle data fetching within the ASSEMBLY_ANNOTATION workflow
        input_data = Channel.empty()
    }
    
    // Execute the genome assembly and annotation workflow
    ASSEMBLY_ANNOTATION(input_data)
    
    // Execute the quality assessment and functional profiling workflow
    // Pass the outputs from assembly workflow as inputs to the profiling workflow
    QUALITY_PROFILE(
        ASSEMBLY_ANNOTATION.out.reads,        // Processed read data
        ASSEMBLY_ANNOTATION.out.assemblies,   // Assembled genomes
        ASSEMBLY_ANNOTATION.out.genes,        // Predicted genes
        ASSEMBLY_ANNOTATION.out.domains,      // Identified protein domains
        ASSEMBLY_ANNOTATION.out.homology      // Homology search results
    )
}