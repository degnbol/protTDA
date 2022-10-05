#!/usr/bin/env python3
from google.cloud import storage
import numpy as np
import tarfile, io, gzip


def cif2xyz(cif):
    """
    - cif: fileobj or other object where each iteration produces a string cif line.
    :return: numpy matrix with 3 columns.
    """
    return np.asarray([line.split()[10:13] for line in cif if line.startswith("ATOM")], dtype=float)


client = storage.Client(project="protTDA")
bucket = client.bucket("public-datasets-deepmind-alphafold")

# version reading a single cif at a time
for blob in bucket.list_blobs(max_results=1):
    break # debug
    if not blob.name.endswith(".cif"): continue
    # if blob.size > 100000: continue
    with blob.open() as cif: xyz = cif2xyz(cif)
    np.save("xyz/" + blob.name.removesuffix(".cif"), xyz)
    
# version reading a proteome at a time that may have multiple compressed cifs.
for blob in bucket.list_blobs(max_results=2, prefix="proteomes"):
    # break
    with tarfile.open(fileobj=io.BytesIO(blob.download_as_bytes())) as tar:
        for member in tar.getmembers():
            if member.name.endswith(".cif.gz"):
                with gzip.open(tar.extractfile(member), 'rt') as cif:
                    xyz = cif2xyz(cif)


