#!/usr/bin/env python3
import sys
from os import path
import json
import h5py as h5, hdf5plugin # plugin for zstd to read compressed reps
import numpy as np
import leidenalg
import igraph as ig
from scipy.sparse import csc_matrix
import re

def leiden(mat):
    G = ig.Graph.Weighted_Adjacency(mat)
    parts = leidenalg.find_partition(G, leidenalg.ModularityVertexPartition)
    comm = np.zeros(mat.shape[0], dtype=int)
    for i, part in enumerate(parts):
        comm[part] = i+1
    return comm

def reps2hyperedges(reps):
    """
    - reps: matrix of integers, e.g. read from HDF5 PH.
    returns: list of sets of integers. Each top level element is a hyperedge.
    """
    hyperedges = []
    indices = np.asarray(reps[:,0])
    _reps = reps[:, 1:]
    for i in range(max(indices)+1):
        hyperedges.append(np.unique(_reps[indices == i, :]))
    return hyperedges

def hyperedges2B(hyperedges, nNodes=None):
    """
    B is sparse integer matrix with dim (#nodes, #hyperedges).
    - hyperedges: each hyperedge is a set of node indices
    - nNodes: optionally specify the total number of nodes
    """
    Is = np.asarray([n for     h  in           hyperedges  for n in h])
    Js = np.asarray([j for (j, h) in enumerate(hyperedges) for n in h])
    Vs = [1 for _ in range(len(Is))]
    if nNodes is None:
        return csc_matrix((Vs, (Is, Js)))
    else:
        return csc_matrix((Vs, (Is, Js)), shape=(nNodes, len(hyperedges)))

def clique_expansion(mat):
    N, M = mat.shape
    ex = np.zeros((N, N))
    for j in range(M):
        he = mat[:, j]
        Is = np.nonzero(he)[0]
        for i in Is:
            for ii in Is:
                if i != ii:
                    ex[i,ii] = (he[i] + he[ii]) / 2
    return ex

def reps2leiden(reps, bars, N):
    if len(reps) == 0: return []
    B = hyperedges2B(reps2hyperedges(reps), N)
    persistence = bars[:,-1]
    H = B.toarray() * persistence
    G = clique_expansion(H)
    return leiden(G).tolist()

def read_hdf5(path):
    with h5.File(path) as fh:
        return dict(
            N=fh["Cas"].shape[1],
            # indices stored 1-indexed.
            # Convert them here when reading so all python code is with 0-index.
            reps1=fh["reps1"][:,:].T - 1,
            reps2=fh["reps2"][:,:].T - 1,
            bars1=fh["bars1"][:,:].T,
            bars2=fh["bars2"][:,:].T,
        )

def hdf52leiden(path, dim):
    PH = read_hdf5(path)
    return reps2leiden(PH[f"reps{dim}"], PH[f"bars{dim}"], PH["N"])


def hdf5s2leidens(infiles, dims=[1,2]):
    leidens = {}
    for dim in dims:
        leidens[dim] = {}
        for infile in infiles:
            name = path.splitext(path.basename(infile))[0]
            leidens[dim][name] = hdf52leiden(infile, dim)
    return leidens

if __name__ == "__main__":
    infiles = sys.argv[1:]
    leidens = hdf5s2leidens(infiles)

    # pretty format
    jsonstring = json.dumps(leidens, indent=2)
    jsonstring = re.sub(r'([0-9]+),\n\s*', r'\1,', jsonstring)
    print(jsonstring)

