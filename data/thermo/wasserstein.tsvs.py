#!/usr/bin/env python3
import numpy as np
import pandas as pd
# https://github.com/nbonneel/network_simplex
from PD import W
import gzip
import json

df = pd.read_table("thermozymes-acc-unjag-taxed.tsv.gz")

def readPH(path):
    with gzip.open(path) as fp:
        return json.load(fp)

phs = [readPH(p) for p in df.path]

def ph2bars(ph, dim):
    bars = np.asarray(ph[f"bars{dim}"]).T
    pers = bars[:, 1] - bars[:, 0]
    return bars[pers > 1.]

bars1 = [ph2bars(ph,1) for ph in phs]
bars2 = [ph2bars(ph,2) for ph in phs]

n = len(phs)

dists1 = np.zeros([n, n])
for i in range(n):
    print(f"{i}/{n}", end='\r')
    for j in range(i+1, n):
        dists1[i, j] = dists1[j, i] = W(bars1[i], bars1[j])

pd.DataFrame(dists1, columns=df.acc).to_csv("wassersteins1.tsv.gz", sep='\t', index=False)

dists2 = np.zeros([n, n])
for i in range(n):
    print(f"{i}/{n}", end='\r')
    for j in range(i+1, n):
        dists2[i, j] = dists2[j, i] = W(bars2[i], bars2[j])

pd.DataFrame(dists2, columns=df.acc).to_csv("wassersteins2.tsv.gz", sep='\t', index=False)


