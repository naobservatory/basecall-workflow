process BAM_TO_FASTQ {
    label "samtools"

    input:
        path(bam)
        val nanopore_run
    output:
        path '*.fastq.gz'

    shell:
        '''
        # Get base name without .bam extension
        base_name=$(basename !{bam} .bam)

        # Convert BAM to FASTQ and gzip
        samtools fastq !{bam} | gzip -c > "${base_name}.fastq.gz"
        '''
}

process MERGE_BAMS {
    label "samtools"

    input:
        path(bam_files)
        val nanopore_run
    output:
        path("${nanopore_run}-unclassified.bam")
    shell:
        '''
        samtools merge -r -o !{nanopore_run}-unclassified.bam !{bam_files}
        '''
}
