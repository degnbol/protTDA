#!/usr/bin/env python3
import numpy as np
import h5py, hdf5plugin
import json

# heme example for publication.
# Figure S3.

fid = h5.File("./P6990.h5")
g = fid["P69905"]


out = {}

# ... more extractions in REPL from g

out["bars1"] = g["bars1"][:,:].tolist()
out["bars2"] = g["bars2"][:,:].tolist()

_reps1 = []

for i in range(1, max(reps1[0,:])+1):
    _reps1.append([])
    rep = reps1[1:, reps1[0,:] == i]
    for j in range(rep.shape[1]):
        _reps1[-1].append(rep[:, j].tolist())

_reps2 = []

for i in range(1, max(reps2[0,:])+1):
    _reps2.append([])
    rep = reps2[1:, reps2[0,:] == i]
    for j in range(rep.shape[1]):
        _reps2[-1].append(rep[:, j].tolist())

out["reps1"] = _reps1
out["reps2"] = _reps2

out["accession"] = "P69905"

with open("./P69905.json", 'w') as fp:
    json.dump(out, fp, indent=2)

