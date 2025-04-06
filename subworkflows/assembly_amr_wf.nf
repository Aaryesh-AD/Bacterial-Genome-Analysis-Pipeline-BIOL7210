#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Import process modules
include { GET_SRR }      from '../modules/get_srr'
include { FASTP }        from '../modules/fastp'
include { SPADES }       from '../modules/spades'
include { QUAST }        from '../modules/quast'
include { PRODIGAL }     from '../modules/prodigal'
include { AMR_FINDER }   from '../modules/amr_finder'

/**
 * Streamlined workflow for bacterial genome assembly and AMR gene detection
 *
 * This workflow performs the following steps:
 * 1. Data acquisition (SRA download if applicable)
 * 2. Read quality control and trimming
 * 3. De novo genome assembly
 * 4. Assembly quality assessment
 * 5. Gene prediction
 * 6. Antimicrobial resistance gene detection
 */
workflow ASSEMBLY_AMR_WORKFLOW {
    take:
        input_data   // Channel: [sample_id, read1, read2] or empty if using SRA

    main:
        // STEP 1: DATA ACQUISITION
        // Either use input reads or download from SRA
        if (params.use_sra) {
            log.info "Downloading reads from SRA..."
            Channel
                .fromList(params.sra_ids.tokenize(','))
                .set { sra_ids_ch }
            
            GET_SRR(sra_ids_ch)
            reads_ch = GET_SRR.out.reads
        } else {
            reads_ch = input_data
        }
        
        // STEP 2: READ QUALITY CONTROL
        log.info "Running read quality control..."
        FASTP(reads_ch)
        
        // STEP 3: GENOME ASSEMBLY
        log.info "Performing de novo genome assembly..."
        SPADES(FASTP.out.reads)
        
        // STEP 4: ASSEMBLY QUALITY ASSESSMENT (in parallel)
        log.info "Assessing assembly quality..."
        QUAST(SPADES.out)
        
        // STEP 5: GENE PREDICTION
        log.info "Predicting protein-coding genes..."
        PRODIGAL(SPADES.out)
        
        // STEP 6: AMR GENE DETECTION
        log.info "Identifying antimicrobial resistance genes..."
        AMR_FINDER(PRODIGAL.out)
        
        // Create a summary report that combines key results
        // We need to properly handle the AMR_FINDER output
        // AMR_FINDER.out[0] contains the tuple with sample_id and amr_tsv
        amr_results = AMR_FINDER.out[0]
        
        // Join the AMR and QUAST results using sample_id as the key
        amr_results
            .join(QUAST.out)
            .set { results_ch }
            
        // Generate a final summary report
        results_ch.map { sample_id, amr_tsv, quast_dir ->
            """
            ==== ANALYSIS SUMMARY FOR: ${sample_id} ====
            
            Assembly Quality:
            - See detailed metrics in: ${quast_dir}
            
            AMR Detection:
            - Resistance genes found: ${params.outdir}/amr_finder/results/${amr_tsv}
            
            Analysis completed successfully!
            """
        }
        .collectFile(
            name: 'analysis_summary.txt',
            storeDir: params.outdir
        )
            
    emit:
        reads = reads_ch           // [sample_id, read1, read2]: Processed reads
        assemblies = SPADES.out    // [sample_id, contigs]: Assembled genomes
        quast = QUAST.out          // [sample_id, quast_dir]: Assembly QC results
        genes = PRODIGAL.out       // [sample_id, proteins, gff, stats]: Predicted genes
        amr = AMR_FINDER.out[0]    // [sample_id, amr_tsv]: AMR results
}