// Basecall Nanopore pod5 files
process BASECALL_POD_5_SIMPLEX {
    label "dorado"
    label "basecall"
    accelerator 1
    memory '16 GB'

    input:
        tuple val(batch_id), path(batch_dir)
        val kit
        val nanopore_run

    output:
        tuple val(batch_id), path("*.bam"), emit: bam

    shell:
        '''
        nanopore_run=!{nanopore_run}
        batch_id=!{batch_id}
        batch_dir=!{batch_dir}

        # Dorado basecalling
        dorado basecaller --estimate-poly-a sup !{batch_dir} --kit-name !{kit} > ${nanopore_run}-${batch_id}.bam

        '''
}

process BASECALL_POD_5_DUPLEX {
    label "dorado"
    label "basecall"
    accelerator 1
    memory '16 GB'

    input:
        tuple val(batch_id), path(batch_dir)
        val kit
        val nanopore_run

    output:
        tuple val(batch_id), path("*.bam"), emit: bam

    shell:
        '''
        nanopore_run=!{nanopore_run}
        batch_id=!{batch_id}
        batch_dir=!{batch_dir}

        # Dorado basecalling
        dorado duplex sup !{batch_dir} > ${nanopore_run}-${batch_id}.bam
        '''
}

// Demultiplex basecalled BAM files
process DEMUX_POD_5 {
    label "dorado"
    label "demux"
    accelerator 1
    memory '16 GB'

    input:
        tuple val(batch_id), path(bam)
        val kit
        val nanopore_run
    output:
        path('demultiplexed/*'), emit: demux_bam

    script:
        """
        nanopore_run=${nanopore_run}
        batch_id=${batch_id}

        # Demultiplex
        dorado demux --no-classify --output-dir demultiplexed/ ${bam}

        # Rename output files
        for f in demultiplexed/*; do
            [[ "\$f" == *.bam ]] || { echo "Error: File \$f is not a BAM file"; exit 1; }
            barcode=\$(basename "\$f" | sed -E 's/.*_(.+)\\.bam\$/\\1/')
            barcode=\$(echo "\$barcode" | sed -E 's/barcode//')
            mv "\$f" "demultiplexed/\${nanopore_run}-\${batch_id}-\${barcode}-div.bam"
        done
        """
}