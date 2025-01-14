// Basecall Nanopore pod5 files
process BASECALL_POD_5_SIMPLEX {
    label "dorado"
    label "basecall"
    accelerator 1
    memory '8 GB'

    input:
        path(pod_5_dir)
        val kit
        val nanopore_run

    output:
        path("*.bam"), emit: bam
        path("sequencing_summary_*.txt"), emit: summary

    shell:
        '''
        nanopore_run=!{nanopore_run}
        # Extract batch number
        batch_num=$(basename !{pod_5_dir} | grep -o '[0-9]\\+')

        # Dorado basecalling
        dorado basecaller sup !{pod_5_dir} --kit-name !{kit} > ${nanopore_run}-${batch_num}.bam

        dorado summary ${nanopore_run}-${batch_num}.bam > sequencing_summary_${nanopore_run}-${batch_num}.txt
        '''
}

process BASECALL_POD_5_DUPLEX {
    label "dorado"
    label "basecall"
    accelerator 1
    memory '8 GB'

    input:
        path(pod_5_dir)
        val kit
        val nanopore_run

    output:
        path("*.bam"), emit: bam
        path("sequencing_summary_*.txt"), emit: summary

    shell:
        '''
        nanopore_run=!{nanopore_run}
        # Extract batch number
        batch_num=$(basename !{pod_5_dir} | grep -o '[0-9]\\+')

        # Dorado basecalling
        dorado duplex sup !{pod_5_dir} > ${nanopore_run}-${batch_num}.bam

        dorado summary ${nanopore_run}-${batch_num}.bam > sequencing_summary_${nanopore_run}-${batch_num}.txt
        '''
}

// Demultiplex basecalled BAM files
process DEMUX_POD_5 {
    label "dorado"
    label "demux"
    accelerator 1
    memory '8 GB'

    input:
        path bam
        val kit
        val nanopore_run
    output:
        path('demultiplexed/*'), emit: demux_bam

    script:
        """
        nanopore_run=${nanopore_run}
        # Extract batch number
        batch_num=\$(basename ${bam} | grep -o '[0-9]\\+' | tail -n1)

        # Demultiplex
        dorado demux --no-classify --output-dir demultiplexed/ ${bam}

        # Print contents of demultiplexed directory
        ls -la demultiplexed/*

        # Rename output files
        for f in demultiplexed/*; do
            [[ "\$f" == *.bam ]] || { echo "Error: File \$f is not a BAM file"; exit 1; }
            barcode=\$(basename "\$f" | sed -E 's/.*_(.+)\\.bam\$/\\1/')
            barcode=\$(echo "\$barcode" | sed -E 's/barcode//')
            mv "\$f" "demultiplexed/\${nanopore_run}-\${barcode}-div\${batch_num}.bam"
        done
        """
}