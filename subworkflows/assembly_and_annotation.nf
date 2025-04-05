nextflow.enable.dsl=2

// Import process workflows from corresponding modules
include { GET_SRR_WF as GET_SRR } from '../modules/get_srr'
include { SPADES_WF as SPADES } from '../modules/spades'
include { PRODIGAL_WF as PRODIGAL } from '../modules/prodigal'
include { DIAMOND_WF as DIAMOND } from '../modules/diamond'
include { HMMSCAN_WF as HMMSCAN } from '../modules/hmmscan'

/**
 * Bacterial Genome Assembly and Annotation Subworkflow
 * This workflow performs a complete assembly and annotation pipeline including:
 * - Read acquisition (local or from SRA)
 * - Genome assembly
 * - Gene prediction
 * - Protein domain annotation
 * - Homology-based functional annotation
 */
workflow ASSEMBLY_ANNOTATION {
    take:
        input_data   // Input channel: either [sample_id, read1, read2] for local data or SRR IDs for SRA data
    
    main:
        // Determine input source and prepare reads channel
        if (params.use_sra) {
            // Process SRA accessions when using public data
            log.info "Processing SRA data with accessions: ${params.sra_ids}"
            sra_ids_ch = Channel.fromList(params.sra_ids.tokenize(','))
            reads_ch = GET_SRR(sra_ids_ch)
        } else {
            // Use pre-existing local sequencing data
            log.info "Processing local sequencing data from: ${params.reads}"
            reads_ch = input_data
        }
        
        // De novo genome assembly using SPAdes
        SPADES(reads_ch)
        
        // Protein-coding gene prediction with Prodigal
        PRODIGAL(SPADES.out)
        
        // Functional annotation processes
        // 1. Protein domain identification using HMMER/hmmscan against Pfam database
        HMMSCAN(PRODIGAL.out)
        
        // 2. Sequence homology search using DIAMOND against reference database
        DIAMOND(PRODIGAL.out)
    
    emit:
        reads = reads_ch                            // [sample_id, read1, read2]: Raw or processed reads
        assemblies = SPADES.out                     // [sample_id, contigs]: Assembled genome contigs
        genes = PRODIGAL.out                        // [sample_id, faa, gff, stats]: Predicted genes and proteins
        domains = HMMSCAN.out                       // [sample_id, tbl, domtbl]: Identified protein domains
        homology = DIAMOND.out                      // [sample_id, tsv]: Homology search results
}