/***********************************************************************************************
| WORKFLOW: BASECALLING NANOPORE SQUIGGLE DATA |
***********************************************************************************************/

import groovy.json.JsonOutput
import java.time.LocalDateTime

/***************************
| MODULES AND SUBWORKFLOWS |
***************************/

include { BATCH_POD_5 } from "../modules/local/batchPod5"
include { BASECALL_POD_5_SIMPLEX } from "../modules/local/dorado"
include { BASECALL_POD_5_DUPLEX } from "../modules/local/dorado"
include { DEMUX_POD_5 } from "../modules/local/dorado"
include { BAM_TO_FASTQ } from "../modules/local/samtools"
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

        // Read samplesheet
        batch_ch = Channel
            .fromPath(params.pod5_sheet)
            .splitCsv(header: true)
            .map { row -> tuple(row.batch_id, row.batch_dir) }

        batch_ch.view()

        // Basecalling
        if (params.duplex) {
            bam_ch = BASECALL_POD_5_DUPLEX(batch_pod5_ch, params.kit, params.delivery)
            bam_flat_ch = bam_ch.bam.flatten()
        } else {
            bam_ch = BASECALL_POD_5_SIMPLEX(batch_pod5_ch, params.kit, params.delivery)
            if (params.demux) {
                demux_ch = DEMUX_POD_5(bam_ch.bam, params.kit, params.delivery)
                bam_flat_ch = demux_ch.demux_bam.flatten()
            }


        // Convert to FASTQ
        fastq_ch = BAM_TO_FASTQ(bam_flat_ch, params.delivery)

        // publish:
        fastq_ch >> "raw"

}
