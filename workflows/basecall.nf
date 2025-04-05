/***********************************************************************************************
| WORKFLOW: BASECALLING NANOPORE SQUIGGLE DATA |
***********************************************************************************************/

import groovy.json.JsonOutput
import java.time.LocalDateTime

/***************************
| MODULES AND SUBWORKFLOWS |
***************************/

include { BASECALL_POD_5_SIMPLEX } from "../modules/local/dorado"
include { BASECALL_POD_5_DUPLEX } from "../modules/local/dorado"
include { DEMUX_POD_5 } from "../modules/local/dorado"
include { BAM_TO_FASTQ as BAM_TO_FASTQ_DEMUX } from "../modules/local/samtools"
include { BAM_TO_FASTQ as BAM_TO_FASTQ_UNCLASSIFIED } from "../modules/local/samtools"
nextflow.preview.output = true

/*****************
| MAIN WORKFLOWS |
*****************/

// Complete primary workflow
workflow BASECALL {
    main:
    // Start time
    start_time = new Date()
    start_time_str = start_time.format("YYYY-MM-dd HH:mm:ss z (Z)")

    // Batching
    pod5_ch = channel.fromPath(params.pod_5_dir)

    // file -> tuple(file, division)
    pod5_ch = pod5_ch.collect(flat: false, sort: true)
        .flatMap { files ->
        files.withIndex().collect { file, index ->
            tuple(file, String.format("div%04d", index + 1))
        }
    }

    // Barcodes
    barcodes_ch = file(params.barcodes).readLines().collect()

    // Basecalling
    if (params.duplex) {
        bam_ch = BASECALL_POD_5_DUPLEX(pod5_ch, params.kit, params.nanopore_run)
        final_bam_ch = bam_ch.bam.flatten()
    } else {
        bam_ch = BASECALL_POD_5_SIMPLEX(pod5_ch, params.kit, params.nanopore_run)
        if (params.demux) {
            demux_ch = DEMUX_POD_5(bam_ch.bam, params.kit, params.nanopore_run, barcodes_ch)
            final_bam_ch = demux_ch.demux_bam.flatten()
            unclassified_bam_ch = demux_ch.unclassified_bam.flatten()
        }
    }

    // Convert to FASTQ
    classified_fastq_ch = BAM_TO_FASTQ_DEMUX(final_bam_ch, params.nanopore_run)
    unclassified_fastq_ch = BAM_TO_FASTQ_UNCLASSIFIED(unclassified_bam_ch, params.nanopore_run)

    publish:
        classified_fastq_ch >> "raw"
        unclassified_fastq_ch >> "unclassified"
}
