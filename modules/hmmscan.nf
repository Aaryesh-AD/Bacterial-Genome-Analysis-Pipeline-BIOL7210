/**
 * Protein Domain Annotation using HMMSCAN
 *
 * This module runs HMMSCAN against predicted protein sequences to identify
 * conserved protein domains using the Pfam database. It handles the database
 * preparation if needed and performs the scan in a temporary directory to
 * avoid issues with path names containing spaces.
 */

process HMMSCAN {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(proteins), path(gff), path(stats)
    
    output:
    tuple val(sample_id), path("${sample_id}_hmmscan.tbl"), path("${sample_id}_hmmscan.domtbl")
    
    script:
    """
    # Create a temporary directory in /tmp (avoiding spaces in paths)
    TMPDIR=\$(mktemp -d -p /tmp hmmscan_XXXXXX)
    
    # Copy input protein file to the temp directory for safe processing
    cp ${proteins} \$TMPDIR/input.faa
    
    # Move to the temp directory for all operations
    cd \$TMPDIR
    
    # Set up the Pfam database - download if not available
    if [ ! -f "${params.pfam_db}" ]; then
        echo "Downloading Pfam-A HMM database..."
        wget -q ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
        gunzip Pfam-A.hmm.gz
        
        # Prepare the HMM database for faster searches
        hmmpress Pfam-A.hmm
        
        PFAM_DB="Pfam-A.hmm"
    else
        # Use existing database by copying to temp directory
        cp ${params.pfam_db}* ./
        PFAM_DB="\$(basename ${params.pfam_db})"
    fi
    
    # Run hmmscan using specified parameters
    hmmscan \
        --cpu ${task.cpus} \
        --domtblout output.domtbl \
        --tblout output.tbl \
        --cut_ga \
        \$PFAM_DB \
        input.faa
    
    # Transfer results back to the working directory
    cp output.tbl \${OLDPWD}/${sample_id}_hmmscan.tbl
    cp output.domtbl \${OLDPWD}/${sample_id}_hmmscan.domtbl
    
    # Clean up temporary files
    cd \${OLDPWD}
    rm -rf \$TMPDIR
    """
}

/**
 * HMMSCAN workflow component
 * This workflow wraps the HMMSCAN process, allowing it to be used as a modular component in larger workflows.
 * It takes protein sequences as input and outputs the HMMSCAN results.
 */
workflow HMMSCAN_WF {
    take: proteins
    main:
        HMMSCAN(proteins)
    emit:
        HMMSCAN.out
}