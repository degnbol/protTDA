#!/usr/bin/env python3
from skfda.misc.metrics import fisher_rao_distance
from skfda import FDataGrid
import gzip, json
import os
import numpy as np
import pandas as pd
from glob import glob

df = pd.read_table("./blast.tsv.gz")

cent2s = []
for row in df.itertuples():
    fname = glob("PH/" + row.pdb + '_' + row.chain.upper() + "_1*.json.gz")
    assert len(fname) == 1
    fname, = fname
    with gzip.open(fname) as fh:
        cent2s.append(json.load(fh)["cent2"])


def distance(f, g):
    nf = len(f)
    ng = len(g)
    _f = np.zeros(max(nf,ng))
    _g = np.zeros(max(nf,ng))
    _f[range(nf)] = f
    _g[range(ng)] = g
    _f = FDataGrid(_f)
    _g = FDataGrid(_g)
    return fisher_rao_distance(_f, _g)[0]

dists = np.zeros([len(cent2s), len(cent2s)])
for i in range(len(cent2s)):
    for j in range(i+1, len(cent2s)):
        dists[i,j] = distance(cent2s[i], cent2s[j])

np.savetxt("fisherrao.ssv", dists, delimiter=" ")


