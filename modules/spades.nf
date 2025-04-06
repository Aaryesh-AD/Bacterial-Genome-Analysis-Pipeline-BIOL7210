/**
 * De novo genome assembly using SPAdes
 *
 * This module assembles bacterial genomes from paired-end reads using the SPAdes
 * assembler. It supports different assembly modes (isolate, meta, rna, etc.)
 * and handles temporary files efficiently.
 */
process SPADES {
    tag "$sample_id"
    publishDir "${params.outdir}/assemblies", mode: "copy",
        saveAs: { filename ->
            if (filename.endsWith(".fasta")) "${sample_id}/${filename}"
            else null
        }
    
    input:
    tuple val(sample_id), path(read1), path(read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_contigs.fasta")
    
    script:
    def memory = task.memory.toGiga()
    """
    # Create a temporary directory for SPAdes output
    TMPDIR=\$(mktemp -d -p /tmp spades_XXXXXX)
    
    # Execute SPAdes assembler with configurable mode
    spades.py \
        --${params.spades_mode} \
        -1 ${read1} \
        -2 ${read2} \
        -o \$TMPDIR \
        -t ${task.cpus} \
        -m ${params.spades_memory ?: memory} \
        ${params.spades_careful ? '--careful' : ''} \
        --phred-offset 33
    
    # Copy the assembled contigs with a sample-specific filename
    cp \$TMPDIR/contigs.fasta ${sample_id}_contigs.fasta
    
    # Save log files for troubleshooting if needed
    mkdir -p logs
    cp \$TMPDIR/spades.log logs/${sample_id}_spades.log
    
    # Remove temporary directory to free disk space
    rm -rf \$TMPDIR
    """
}