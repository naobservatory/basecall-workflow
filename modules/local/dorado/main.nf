// Basecall Nanopore pod5 files
process BASECALL_POD_5_SIMPLEX {
    label "dorado"
    label "basecall"
    accelerator 1
    memory '16 GB'

    input:
        tuple path(pod5), val(division)
        val kit
        val nanopore_run

    output:
        path("*.bam"), emit: bam
        path("sequencing_summary_*.txt"), emit: summary

    shell:
        '''
        nanopore_run=!{nanopore_run}

        # Dorado basecalling
        dorado basecaller sup !{pod5} --kit-name !{kit} > ${nanopore_run}-!{division}.bam

        dorado summary ${nanopore_run}-!{division}.bam > sequencing_summary_${nanopore_run}-!{division}.txt
        '''
}

process BASECALL_POD_5_DUPLEX {
    label "dorado"
    label "basecall"
    accelerator 1
    memory '16 GB'

    input:
        tuple path(pod5), val(division)
        val kit
        val nanopore_run

    output:
        tuple path("*.bam"), val(division), emit: bam
        tuple path("sequencing_summary_*.txt"), val(division), emit: summary

    shell:
        '''
        nanopore_run=!{nanopore_run}

        # Dorado basecalling
        dorado duplex sup !{pod5} > ${nanopore_run}-!{division}.bam

        dorado summary ${nanopore_run}-!{division}.bam > sequencing_summary_${nanopore_run}-!{division}.txt
        '''
}

// Demultiplex basecalled BAM files
process DEMUX_POD_5 {
    label "dorado"
    label "demux"
    accelerator 1
    memory '16 GB'

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