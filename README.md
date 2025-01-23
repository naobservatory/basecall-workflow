# Nanopore Basecalling Workflow

This Nextflow pipeline is designed to process Oxford Nanopore raw signal data (POD5 files) through basecalling and optional demultiplexing steps. It supports both simplex and duplex basecalling modes using Dorado.

## Pipeline Description

### Overview

The pipeline consists of a single workflow that processes Nanopore POD5 files through several phases:

1. A **batching phase** where POD5 files are grouped into batches to allow parallelized basecalling
2. A **basecalling phase** using Dorado in either simplex or duplex mode
3. An optional **demultiplexing phase** for barcoded samples
4. A final **conversion phase** to generate FASTQ files from BAM output

### Pipeline Outputs

The workflow produces the following key outputs:

1. `raw/`: Directory containing the final FASTQ files
2. `summary/`: Directory containing basecalling summary statistics

## Using the Workflow

### Installation & Setup

1. Install Nextflow (23.04.0+)
2. Install Docker
3. Set up [AWS BATCH](https://github.com/naobservatory/mgs-workflow/tree/master#:~:text=The%20batch%20profile%20is,your%20Batch%20job%20queue.)
4. Clone this repository

### Running the Pipeline

Basic usage:

Create a new directory, name it after the delivery, copy in basecall.config as nextflow.config, and set the parameters. Params:

- duplex
- demux
- batch_size (sizing for batching pod5 files for parallelized base-calling)
- nanopore_run (name of run/delivery)
- kit (name of ONT kit, needed for demux'ing)
- pod_5_dir (path to dir containing pod5 files)
- base_dir (path to where output will be saved to)

Once that is done, you can switch into the directory and run

```bash
nextflow run .. -resume
```
