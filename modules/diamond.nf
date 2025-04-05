/*
 * Protein homology search against reference database using DIAMOND
 *
 * This module performs fast protein homology searches using DIAMOND, which is much 
 * faster than BLAST while maintaining good sensitivity. It downloads UniRef90 as a 
 * reference database if one is not provided, creates a DIAMOND database, and runs 
 * a search for each sample's protein sequences.
 */

process DIAMOND {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(proteins), path(gff), path(stats)
    
    output:
    tuple val(sample_id), path("${sample_id}_diamond.tsv")
    
    script:
    """
    # Create a temporary directory for database operations
    TMPDIR=\$(mktemp -d -p /tmp diamond_XXXXXX)
    
    # Prepare reference database - download and build if not already available
    if [ ! -f "${params.nr_db}.dmnd" ] && [ ! -f "\$TMPDIR/nr.dmnd" ]; then
        mkdir -p \$TMPDIR
        cd \$TMPDIR
        
        echo "Downloading reference protein database..."
        # Use UniRef90 as reference - more manageable size with comprehensive coverage
        wget -q ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
        gunzip uniref90.fasta.gz
        
        # Convert FASTA to DIAMOND database format
        diamond makedb --in uniref90.fasta -d uniref90
        
        NR_DB="\$TMPDIR/uniref90"
    else
        # Use the existing database specified in parameters
        NR_DB="${params.nr_db}"
    fi
    
    # Perform protein homology search using DIAMOND
    diamond blastp \
        --query ${proteins} \
        --db \$NR_DB \
        --out ${sample_id}_diamond.tsv \
        --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle \
        --max-target-seqs 5 \
        --evalue ${params.diamond_evalue} \
        --threads ${task.cpus}
    
    # Add descriptive header to output file
    sed -i '1i #query\tsubject\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tstitle' ${sample_id}_diamond.tsv
    
    # Remove temporary data to free space
    rm -rf \$TMPDIR
    """
}

workflow DIAMOND_WF {
    take: proteins
    main:
        DIAMOND(proteins)
    emit:
        DIAMOND.out
}