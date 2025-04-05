nextflow.enable.dsl=2

// Import workflows
include { ASSEMBLY_ANNOTATION } from './subworkflows/assembly_and_annotation'
include { QUALITY_PROFILE } from './subworkflows/quality_and_profile'

// Define the main workflow
workflow {
    log.info """
==============================================================================
BIOL7210 FUNCTIONAL GENE DISCOVERY WORKFLOW - Nexflow v${nextflow.version}
==============================================================================
Input: ${params.use_sra ? "SRA IDs: ${params.sra_ids}" : "Reads: ${params.reads}"}
Output dir: ${params.outdir}
==============================================================================
"""

    // Create input channel based on the data source
    if (!params.use_sra) {
        // Use local fastq files
        Channel
            .fromFilePairs(params.reads, flat: true)
            .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
            .set { input_data }
    } else {
        // We'll create the SRA channel inside the ASSEMBLY_ANNOTATION workflow
        input_data = Channel.empty()
    }
    
    // Execute the subworkflows
    ASSEMBLY_ANNOTATION(input_data)
    
    // Execute the quality profile subworkflow
    QUALITY_PROFILE(
        ASSEMBLY_ANNOTATION.out.reads,        // reads
        ASSEMBLY_ANNOTATION.out.assemblies,   // assemblies
        ASSEMBLY_ANNOTATION.out.genes,        // genes
        ASSEMBLY_ANNOTATION.out.domains,      // domains
        ASSEMBLY_ANNOTATION.out.homology      // homology
    )
}