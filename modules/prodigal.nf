/**
 * Gene prediction using Prodigal
 *
 * This module identifies protein-coding genes in bacterial genomes using
 * Prodigal (Prokaryotic Dynamic Programming Gene-finding Algorithm).
 */
process PRODIGAL {
    tag "$sample_id"
    publishDir "${params.outdir}/prodigal", mode: "copy",
        saveAs: { filename ->
            if (filename.endsWith(".faa")) "proteins/${filename}"
            else if (filename.endsWith(".gff")) "annotations/${filename}"
            else if (filename.endsWith(".stats")) "stats/${filename}"
            else null
        }
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}.faa"), path("${sample_id}.gff"), path("${sample_id}_prodigal.stats")
    
    script:
    """
    # Run Prodigal for gene prediction with configurable genetic code
    prodigal \
        -i ${contigs} \
        -a ${sample_id}.faa \
        -f gff \
        -o ${sample_id}.gff \
        -p ${params.prodigal_mode} \
        -q > ${sample_id}_prodigal.stats
    
    # Calculate and append the total number of predicted genes to stats file
    echo "# Predicted genes: \$(grep -c ">" ${sample_id}.faa)" >> ${sample_id}_prodigal.stats
    
    # Calculate length statistics for predicted proteins
    echo "# Protein length statistics:" >> ${sample_id}_prodigal.stats
    grep ">" ${sample_id}.faa | sed 's/.*# \\([0-9]*\\) # \\([0-9]*\\) .*/\\2-\\1/' | \
        awk -F'-' '{print \$2-\$1+1}' | sort -n | \
        awk 'BEGIN {min=999999; max=0; sum=0; n=0} 
            {sum+=\$1; if(\$1<min) min=\$1; if(\$1>max) max=\$1; n++} 
            END {printf "# Min: %d, Max: %d, Mean: %.1f, Total: %d\\n", min, max, sum/n, n}' \
        >> ${sample_id}_prodigal.stats
    """
}