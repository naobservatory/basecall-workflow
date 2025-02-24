#!/usr/bin/env python3
import os
import sys
import shutil
import subprocess
import argparse
from multiprocessing import Pool

# Usage: ./basecall.py NAO-ONT-20240519-practice

BATCH_SIZE=(1024**2) * 8 # 8MB

parser = argparse.ArgumentParser()
parser.add_argument("delivery")
args = parser.parse_args()

# Remove trailing slash from bioproject if present
args.delivery = args.delivery.rstrip('/')

S3_DIR = os.path.expanduser("~/s3-mnt/nao-restricted/")
def s3_mounted():
    return os.path.exists(os.path.join(S3_DIR, "nao-restricted-exists"))

if not s3_mounted():
    os.makedirs(S3_DIR, exist_ok=True)
    subprocess.check_call(["mount-s3", "--allow-write", "nao-restricted", S3_DIR])

assert s3_mounted()

s3_in_dir = os.path.join(S3_DIR, args.delivery, "pod5")
s3_out_dir = os.path.join(S3_DIR, args.delivery, "batched")

def batch_input_files(max_files_per_batch=10):
    current_batch = []
    current_batch_size = 0
    total_files = 0

    for fname in os.listdir(s3_in_dir):
        total_files += 1
        path = os.path.join(s3_in_dir, fname)
        size = os.path.getsize(path)

        if (current_batch_size + size > BATCH_SIZE or
            len(current_batch) >= max_files_per_batch) and current_batch:

            yield current_batch
            current_batch = []
            current_batch_size = 0

        current_batch.append(path)
        current_batch_size += size

    if current_batch:
        yield current_batch

# Process batches and write samplesheet
with open("pod5_sheet.csv", "w") as f:
    f.write("batch_id\tbatch_dir\n")

    for i, batch in enumerate(batch_input_files()):
        batch_id = f"batch_{i:04d}"
        batch_dir = os.path.join(s3_out_dir, batch_id)
        os.makedirs(batch_dir, exist_ok=True)
        f.write(f"{batch_id}\t{batch_dir}\n")

        with Pool() as pool:
            def copy_file(pod5_file):
                pod5_fname = os.path.basename(pod5_file)
                pod5_out_path = os.path.join(batch_dir, pod5_fname)
                shutil.copy2(pod5_file, pod5_out_path)
                return 1

            pool.map(copy_file, batch)

