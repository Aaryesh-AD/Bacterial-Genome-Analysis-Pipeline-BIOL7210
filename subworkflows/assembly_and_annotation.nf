nextflow.enable.dsl=2

// Import processes from modules
include { GET_SRR_WF as GET_SRR } from '../modules/get_srr'
include { SPADES_WF as SPADES } from '../modules/spades'
include { PRODIGAL_WF as PRODIGAL } from '../modules/prodigal'
include { DIAMOND_WF as DIAMOND } from '../modules/diamond'
include { HMMSCAN_WF as HMMSCAN } from '../modules/hmmscan'

// Assembly and Annotation Subworkflow
workflow ASSEMBLY_ANNOTATION {
    take:
        input_data   // Input: either [sample_id, read1, read2] OR SRR IDs
    
    main:
        // Check if input is SRR IDs or local data
        if (params.use_sra) {
            // Download SRA data
            log.info "Using SRA data: ${params.sra_ids}"
            sra_ids_ch = Channel.fromList(params.sra_ids.tokenize(','))
            reads_ch = GET_SRR(sra_ids_ch)
        } else {
            // Use local data
            log.info "Using local data from: ${params.reads}"
            reads_ch = input_data
        }
        
        // Assembly with SPAdes
        SPADES(reads_ch)
        
        // Gene prediction with Prodigal
        PRODIGAL(SPADES.out)
        
        // Functional annotation
        // 1. Domain detection with HMMER/hmmscan
        HMMSCAN(PRODIGAL.out)
        
        // 2. Homology search with DIAMOND
        DIAMOND(PRODIGAL.out)
    
    emit:
        reads = reads_ch                            // [sample_id, read1, read2]
        assemblies = SPADES.out                     // [sample_id, contigs]
        genes = PRODIGAL.out                        // [sample_id, faa, gff, stats]
        domains = HMMSCAN.out                       // [sample_id, tbl, domtbl]
        homology = DIAMOND.out                      // [sample_id, tsv]
}