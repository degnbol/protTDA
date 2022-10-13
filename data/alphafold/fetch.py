#!/usr/bin/env python3
from google.cloud import storage
import numpy as np

client = storage.Client(project="protTDA")
bucket = client.bucket("public-datasets-deepmind-alphafold")

def gen_blobs(max_results=None):
    for blob in client.list_blobs(bucket, max_results=max_results):
        if blob.name.endswith(".cif"): yield blob

