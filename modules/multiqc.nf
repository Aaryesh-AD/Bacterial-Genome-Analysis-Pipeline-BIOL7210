process MULTIQC {
    input:
    path inputs
    
    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data", emit: data
    
    script:
    """
    multiqc . -f
    """
}

workflow MULTIQC_WF {
    take: reports
    main:
        MULTIQC(reports)
    emit:
        report = MULTIQC.out.report
        data = MULTIQC.out.data
}