# Nanopore Basecalling Workflow

This Nextflow pipeline is designed to process Oxford Nanopore raw signal data (POD5 files) through basecalling and optional demultiplexing steps. It supports both simplex and duplex basecalling modes using Dorado.

## Pipeline Description

### Overview

The pipeline consists of a single workflow that processes Nanopore POD5 files through several phases:

1. A **batching phase** where POD5 files are grouped into manageable batches
2. A **basecalling phase** using Dorado in either simplex or duplex mode
3. An optional **demultiplexing phase** for barcoded samples
4. A final **conversion phase** to generate FASTQ files from BAM output

### Workflow Steps

1. **Batching**: The `BATCH_POD_5` module processes the input POD5 directory and creates batches of a specified size
2. **Basecalling**: Either `BASECALL_POD_5_SIMPLEX` or `BASECALL_POD_5_DUPLEX` is used depending on configuration
3. **Demultiplexing**: If enabled, `DEMUX_POD_5` separates reads by barcode
4. **Conversion**: `BAM_TO_FASTQ` converts the final BAM files to FASTQ format

### Pipeline Outputs

The workflow produces the following key outputs:

1. `raw/`: Directory containing the final FASTQ files
2. `summary/`: Directory containing basecalling summary statistics

## Using the Workflow

### Installation & Setup

1. Install Nextflow (23.04.0+)
2. Install Docker
3. Clone this repository
4. Configure your compute environment (local or cloud)

### Running the Pipeline

Basic usage:

```bash
nextflow run main.nf -profile <profile_name> --pod_5_dir <path_to_pod5_files> --kit <kit_name>
```

Key Parameters:
- `--pod_5_dir`: Directory containing POD5 files
- `--kit`: Sequencing kit used (e.g., "dna_r10.4.1_e8.2_400bps_sup")
- `--batch_size`: Number of POD5 files per batch (default: 10)
- `--duplex`: Enable duplex basecalling (default: false)
- `--demux`: Enable demultiplexing (default: false)

### Profiles

The pipeline comes with several built-in configuration profiles:
- `standard`: For local execution
- `docker`: For running with Docker containers
- `aws`: For running on AWS infrastructure

## Troubleshooting

Common issues and their solutions:

1. **Insufficient Memory**: Increase available memory or reduce batch size
2. **Missing POD5 Files**: Verify input directory path and file permissions
3. **Docker Issues**: Ensure Docker is running and has sufficient resources

## Contributing

Please submit issues and pull requests through GitHub.

## License

This project is licensed under [insert license].
