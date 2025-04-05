/*
 * MultiQC is a tool that aggregates bioinformatics results across many samples
 * into a single report. This module processes multiple QC reports from various 
 * tools and creates a consolidated interactive HTML report.
 */

process MULTIQC {
    input:
    path inputs   // Path to directory with QC reports to be processed

    output:
    path "multiqc_report.html", emit: report   // HTML report output
    path "multiqc_data", emit: data            // Directory with parsed data

    script:
    """
    multiqc . -f   // Run MultiQC with force overwrite
    """
}

/*
 * This workflow wraps the MultiQC process to make it reusable
 * in other workflows with a standardized interface
 */
workflow MULTIQC_WF {
    take: reports  // Collection of reports to be aggregated

    main:
        MULTIQC(reports)

    emit:
        report = MULTIQC.out.report  // Final HTML report
        data = MULTIQC.out.data      // Parsed data directory
}