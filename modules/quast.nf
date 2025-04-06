/**
 * Assembly quality assessment using QUAST
 *
 * This module evaluates assembly quality using QUAST
 */
process QUAST {
    tag "$sample_id"
    publishDir "${params.outdir}/quast", mode: "copy"
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}_quast")
    
    shell:
    '''
    # Store the current directory path to return to later
    WORK_DIR="$PWD"
    
    # Make sure the output directory exists
    mkdir -p !{sample_id}_quast
    
    # Create a temp directory for QUAST in /tmp (no spaces)
    TEMP_DIR=$(mktemp -d /tmp/quast_XXXXXX)
    
    # Copy assembly to temp dir
    cp !{contigs} $TEMP_DIR/assembly.fa
    
    # Run QUAST in the temporary directory
    cd $TEMP_DIR
    quast.py assembly.fa \
        --output-dir quast_out \
        --threads !{task.cpus} \
        --min-contig !{params.quast_min_contig} \
        --no-icarus
    
    # Copy QUAST output files directly to the output directory
    cp -r quast_out/* /tmp/
    
    # Return to the work dir (using double quotes to handle spaces)
    cd "$WORK_DIR"
    
    # Copy from /tmp to the output directory
    cp -r /tmp/report.txt !{sample_id}_quast/
    cp -r /tmp/report.tsv !{sample_id}_quast/
    cp -r /tmp/report.pdf !{sample_id}_quast/
    cp -r /tmp/icarus* !{sample_id}_quast/ 2>/dev/null || true
    cp -r /tmp/transposed_report* !{sample_id}_quast/
    cp -r /tmp/basic_stats !{sample_id}_quast/
    
    # Create a simple summary
    echo "Assembly Quality Summary for !{sample_id}" > !{sample_id}_quast/summary.txt
    echo "=====================================" >> !{sample_id}_quast/summary.txt
    echo "" >> !{sample_id}_quast/summary.txt
    
    if [ -f !{sample_id}_quast/report.txt ]; then
        echo "Quality metrics from QUAST:" >> !{sample_id}_quast/summary.txt
        echo "" >> !{sample_id}_quast/summary.txt
        cat !{sample_id}_quast/report.txt >> !{sample_id}_quast/summary.txt
    else
        echo "Warning: QUAST did not produce output files." >> !{sample_id}_quast/summary.txt
        echo "Check the log files for errors." >> !{sample_id}_quast/summary.txt
    fi
    
    # Clean up
    rm -rf $TEMP_DIR
    rm -f /tmp/report.txt /tmp/report.tsv /tmp/report.pdf
    rm -rf /tmp/icarus* /tmp/transposed_report* /tmp/basic_stats
    
    # List the contents of the output directory to verify
    echo "Contents of !{sample_id}_quast:"
    ls -la !{sample_id}_quast/
    '''
}