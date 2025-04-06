/**
 * Antimicrobial resistance gene detection using AMRFinderPlus
 */
process AMR_FINDER {
    tag "$sample_id"
    publishDir "${params.outdir}/amr_finder", mode: "copy",
        saveAs: { filename ->
            if (filename.endsWith("_amr.tsv")) "results/$filename"
            else if (filename.endsWith("_amr_summary.txt")) "summaries/$filename"
            else if (filename.contains("amr_logs")) "logs/$filename"
            else null
        }
    
    input:
    tuple val(sample_id), path(proteins), path(gff), path(stats)
    
    output:
    tuple val(sample_id), path("${sample_id}_amr.tsv"), emit: results
    path("${sample_id}_amr_summary.txt"), emit: summary
    path("amr_logs"), emit: logs

    // I dont know half this stuff, copied it from GitHub, but it seems to work.. so thats good
    script:
    // Define organism parameter if specified
    def organism_param = params.amr_organism ? "--organism ${params.amr_organism}" : ""
    
    """
    # Create log directory for debugging
    mkdir -p amr_logs
    
    # Run AMRFinderPlus on protein sequences
    amrfinder \
        -p ${proteins} \
        --output ${sample_id}_amr.tsv \
        --name ${sample_id} \
        ${organism_param} \
        --ident_min ${params.amr_identity ?: 0.9} \
        --coverage_min ${params.amr_coverage ?: 0.9} \
        --plus \
        --threads ${task.cpus} \
        2> amr_logs/${sample_id}_amr.log
    
    # Create a summary of AMR findings
    echo "=== AMR DETECTION SUMMARY FOR ${sample_id} ====" > ${sample_id}_amr_summary.txt
    echo "Analysis date: \$(date)" >> ${sample_id}_amr_summary.txt
    echo "AMRFinderPlus version: \$(amrfinder --version 2>&1 | head -n 1)" >> ${sample_id}_amr_summary.txt
    echo "" >> ${sample_id}_amr_summary.txt
    
    # Get total number of AMR genes
    TOTAL=\$(grep -v "^#" ${sample_id}_amr.tsv | wc -l)
    echo "Total AMR genes detected: \$TOTAL" >> ${sample_id}_amr_summary.txt
    
    # Get antibiotic class summary
    echo "" >> ${sample_id}_amr_summary.txt
    echo "=== Antibiotic Class Summary ===" >> ${sample_id}_amr_summary.txt
    if [ \$TOTAL -gt 0 ]; then
        grep -v "^#" ${sample_id}_amr.tsv | cut -f8 | sort | uniq -c | sort -nr >> ${sample_id}_amr_summary.txt
    else
        echo "No AMR genes detected." >> ${sample_id}_amr_summary.txt
    fi
    
    # Add the summary to the AMR results file
    cat ${sample_id}_amr_summary.txt > header.txt
    echo "" >> header.txt
    echo "=== DETAILED RESULTS ===" >> header.txt
    echo "" >> header.txt
    cat header.txt ${sample_id}_amr.tsv > temp.tsv
    mv temp.tsv ${sample_id}_amr.tsv
    """
}