process BAM_TO_FASTQ {
    label "samtools"

    input:
        path(bam)
        val delivery
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
