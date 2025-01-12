include { BASECALL } from "./workflows/basecall"

workflow {
    BASECALL()
}

output {
    "results" {
        path "results"
        // tags nextflow_file_class: "publish", "nextflow.io/temporary": "false"
    }
}

