/**
 * Prodigal module
 * 
 * This module performs gene prediction using Prodigal on assembled contigs.
 * Prodigal (Prokaryotic Dynamic Programming Gene-finding Algorithm) identifies 
 * protein-coding regions in bacterial and archaeal genomes.
 * 
 * The module produces three main outputs:
 * - Protein sequences (FAA file)
 * - Gene annotations in GFF format
 * - Summary statistics of the prediction process
 */

process PRODIGAL {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}.faa"), path("${sample_id}.gff"), path("${sample_id}_prodigal.stats")
    
    script:
    """
    # Run Prodigal for gene prediction with metagenome mode (-p meta)
    prodigal \
        -i ${contigs} \
        -a ${sample_id}.faa \
        -f gff \
        -o ${sample_id}.gff \
        -p meta \
        -q > ${sample_id}_prodigal.stats
    
    # Calculate and append the total number of predicted genes to stats file
    echo "# Predicted genes: \$(grep -c ">" ${sample_id}.faa)" >> ${sample_id}_prodigal.stats
    """
}

/**
 * Prodigal workflow
 * 
 * A simple workflow wrapper around the PRODIGAL process
 */
workflow PRODIGAL_WF {
    take: assemblies
    main:
        PRODIGAL(assemblies)
    emit:
        PRODIGAL.out
}