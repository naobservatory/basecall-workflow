#!/usr/bin/env python3
import os
import subprocess
import argparse
import json
import tempfile
from multiprocessing import Pool

# Usage: ./prepare_run.py NAO-ONT-20240519-practice
# This script batches pod5 files from a delivery directory and prepares them for processing

BATCH_SIZE = (1024**3)  # 8GB

parser = argparse.ArgumentParser(description="Prepare ONT pod5 files for processing by batching them")
parser.add_argument("delivery", help="Delivery directory name (e.g., NAO-ONT-20240519-practice)")
args = parser.parse_args()

# Remove trailing slash from delivery if present
args.delivery = args.delivery.rstrip('/')

S3_BUCKET = "nao-restricted"
delivery = args.delivery

def list_s3_files(prefix):
    """List files in S3 with the given prefix"""
    s3_pod5_prefix = f"{delivery}/pod5/"
    cmd = ["aws", "s3", "ls", f"s3://{S3_BUCKET}/{s3_pod5_prefix}"]

    result = subprocess.run(cmd, stdout=subprocess.PIPE, text=True, check=True)

    files = []
    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        parts = line.split()
        if len(parts) >= 4:  # Standard S3 ls output format
            file_name = ' '.join(parts[3:])
            size = int(parts[2])
            files.append((file_name, size))

    return files


def copy_file_to_s3(pod5_file, delivery, batch_id):
    """Copy a file from one S3 location to another"""

    origin = f"s3://{S3_BUCKET}/{delivery}/pod5/{pod5_file}"
    destination = f"s3://{S3_BUCKET}/{delivery}/batched/{batch_id}/{pod5_file}"

    # Check if file already exists at destination
    check_cmd = ["aws", "s3", "ls", destination]
    result = subprocess.run(check_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    if result.returncode == 0:
        print(f"File {pod5_file} already exists in batch {batch_id}, skipping...")
        return

    cmd = ["aws", "s3", "cp", origin, destination]

    subprocess.run(cmd, check=True)


def batch_input_files(files, max_files_per_batch=10):
    """Group input files into batches based on size and count constraints"""
    current_batch = []
    current_batch_size = 0

    for file_name, size in files:
        # If adding this file would exceed batch constraints, yield current batch
        if (current_batch_size + size > BATCH_SIZE or
            len(current_batch) >= max_files_per_batch) and current_batch:

            yield current_batch
            current_batch = []
            current_batch_size = 0

        current_batch.append(file_name)
        current_batch_size += size

    # Yield the last batch if not empty
    if current_batch:
        yield current_batch

# # List all pod5 files in the S3 bucket
print(f"Listing pod5 files in s3://{S3_BUCKET}/{delivery}/pod5/...")
pod5_files = list_s3_files(delivery)

if not pod5_files:
    raise FileNotFoundError(f"No pod5 files found in s3://{S3_BUCKET}/{delivery}/pod5/")

print(f"Found {len(pod5_files)} pod5 files to process")

# Process batches and write samplesheet
with open("pod5_sheet.csv", "w") as f:
    f.write("batch_id\tbatch_dir\n")

    for i, batch in enumerate(batch_input_files(pod5_files)):
        batch_id = f"batch_{i:04d}"
        batch_s3_dir = f"s3://{S3_BUCKET}/{delivery}/batched/{batch_id}"

        print(f"Processing batch {batch_id} with {len(batch)} files...")

        # Create the batch directory in S3 (not needed as cp will create it)
        f.write(f"{batch_id}\t{batch_s3_dir}\n")

        for file_name in batch:
            copy_file_to_s3(file_name, delivery, batch_id)


print(f"Prepared batches for {args.delivery}. Sample sheet written to pod5_sheet.csv")

