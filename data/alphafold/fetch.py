#!/usr/bin/env python3
from google.cloud import storage
import numpy as np
import tarfile, io, gzip

def cif2xyz(cif):
    """
    - cif: fileobj or other object where each iteration produces a string cif line.
    :return: numpy matrix with 3 columns.
    """
    xyzs = []
    for line in cif:
        if line.startswith("ATOM"):
            l = line.split()
            if l[3] == "CA":
                xyzs.append(l[10:13])
    return np.asarray(xyzs, dtype=float)


client = storage.Client(project="protTDA")
bucket = client.bucket("public-datasets-deepmind-alphafold")

def gen_xyzs(max_results=None, min_size=None, max_size=None):
    """ Yield numpy array with columns: x, y, z."""
    # *3 since there are 3 files for every .cif file
    for blob in client.list_blobs(bucket, max_results=max_results*3):
        if not blob.name.endswith(".cif"): continue
        if min_size is not None and blob.size < min_size: continue
        if max_size is not None and blob.size > max_size: continue
        with blob.open() as cif:
            yield blob.name.removesuffix(".cif"), cif2xyz(cif)

def gen_xyzs_proteomes(max_results=None, min_size=None, max_size=None):
    """ version reading a proteome at a time that may have multiple compressed cifs. """
    for blob in client.list_blobs(bucket, max_results=max_results, prefix="proteomes"):
        if min_size is not None and blob.size < min_size: continue
        if max_size is not None and blob.size > max_size: continue
        with tarfile.open(fileobj=io.BytesIO(blob.download_as_bytes())) as tar:
            for member in tar.getmembers():
                if member.name.endswith(".cif.gz"):
                    with gzip.open(tar.extractfile(member), 'rt') as cif:
                        yield member.name.removesuffix(".cif.gz"), cif2xyz(cif)


