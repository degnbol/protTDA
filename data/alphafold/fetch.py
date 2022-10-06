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

def gen_xyzs(max_results=None, size_limit=None):
    """ Yield numpy array with columns: x, y, z."""
    for blob in client.list_blobs(bucket, max_results=max_results):
        if not blob.name.endswith(".cif"): continue
        if size_limit is not None and blob.size > size_limit: continue
        with blob.open() as cif:
            yield cif2xyz(cif)

def gen_xyzs_proteomes(max_results=None, size_limit=None):
    """ version reading a proteome at a time that may have multiple compressed cifs. """
    for blob in client.list_blobs(bucket, max_results=max_results, prefix="proteomes"):
        if size_limit is not None and blob.size > size_limit: continue
        with tarfile.open(fileobj=io.BytesIO(blob.download_as_bytes())) as tar:
            for member in tar.getmembers():
                if member.name.endswith(".cif.gz"):
                    with gzip.open(tar.extractfile(member), 'rt') as cif:
                        yield cif2xyz(cif)


