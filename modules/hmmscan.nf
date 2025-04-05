process HMMSCAN {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(proteins), path(gff), path(stats)
    
    output:
    tuple val(sample_id), path("${sample_id}_hmmscan.tbl"), path("${sample_id}_hmmscan.domtbl")
    
    script:
    """
    # Create a temporary directory in /tmp (which never has spaces)
    TMPDIR=\$(mktemp -d -p /tmp hmmscan_XXXXXX)
    
    # Copy input protein file to the temp directory to avoid path issues
    cp ${proteins} \$TMPDIR/input.faa
    
    # Move to the temp directory for all operations
    cd \$TMPDIR
    
    # Download Pfam database if not already present
    if [ ! -f "${params.pfam_db}" ]; then
        echo "Downloading Pfam-A HMM database..."
        wget -q ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
        gunzip Pfam-A.hmm.gz
        
        # Prepare the HMM database
        hmmpress Pfam-A.hmm
        
        PFAM_DB="Pfam-A.hmm"
    else
        # Copy the existing database to the temp directory
        cp ${params.pfam_db}* ./
        PFAM_DB="\$(basename ${params.pfam_db})"
    fi
    
    # Run hmmscan in the temp directory
    hmmscan \
        --cpu ${task.cpus} \
        --domtblout output.domtbl \
        --tblout output.tbl \
        --cut_ga \
        \$PFAM_DB \
        input.faa
    
    # Copy results back to working directory
    cp output.tbl \${OLDPWD}/${sample_id}_hmmscan.tbl
    cp output.domtbl \${OLDPWD}/${sample_id}_hmmscan.domtbl
    
    # Return to original directory and clean up
    cd \${OLDPWD}
    rm -rf \$TMPDIR
    """
}

workflow HMMSCAN_WF {
    take: proteins
    main:
        HMMSCAN(proteins)
    emit:
        HMMSCAN.out
}