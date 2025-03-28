include { BASECALL } from "./workflows/basecall"

workflow {
    BASECALL()
}

output {
    "raw" {
        path "raw"
        tags nextflow_file_class: "publish", "nextflow.io/temporary": "false"
    }
    "logging" {
        path "logging"
        tags nextflow_file_class: "publish", "nextflow.io/temporary": "false"
    }
}
