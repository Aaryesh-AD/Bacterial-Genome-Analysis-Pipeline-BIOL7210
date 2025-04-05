process DIAMOND {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(proteins), path(gff), path(stats)
    
    output:
    tuple val(sample_id), path("${sample_id}_diamond.tsv")
    
    script:
    """
    # Create a temporary directory in /tmp (which never has spaces)
    TMPDIR=\$(mktemp -d -p /tmp diamond_XXXXXX)
    
    # Download and prepare NR database if not present and needs to be downloaded
    if [ ! -f "${params.nr_db}.dmnd" ] && [ ! -f "\$TMPDIR/nr.dmnd" ]; then
        mkdir -p \$TMPDIR
        cd \$TMPDIR
        
        echo "Downloading reference protein database..."
        # Instead of full NR, use UniRef90 which is smaller but comprehensive
        wget -q ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz
        gunzip uniref90.fasta.gz
        
        # Make DIAMOND database
        diamond makedb --in uniref90.fasta -d uniref90
        
        NR_DB="\$TMPDIR/uniref90"
    else
        # Use provided database path
        NR_DB="${params.nr_db}"
    fi
    
    # Run DIAMOND for homology search
    diamond blastp \
        --query ${proteins} \
        --db \$NR_DB \
        --out ${sample_id}_diamond.tsv \
        --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle \
        --max-target-seqs 5 \
        --evalue ${params.diamond_evalue} \
        --threads ${task.cpus}
    
    # Add header
    sed -i '1i #query\tsubject\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tstitle' ${sample_id}_diamond.tsv
    
    # Clean up
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