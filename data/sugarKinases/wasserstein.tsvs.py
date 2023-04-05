#!/usr/bin/env python3
import numpy as np
import pandas as pd
# https://github.com/nbonneel/network_simplex
from PD import W
import gzip
import json

df = pd.read_table("bork1992_table1-unjag-uniprot-path.tsv")
df_t = pd.read_table("../thermo/thermozymes-acc-unjag-taxed.tsv.gz")

def readPH(path):
    with gzip.open(path) as fp:
        return json.load(fp)

phs = [readPH("../alphafold/" + p) for p in df.path]
phs_t = [readPH("../alphafold/" + p) for p in df_t.path]

def ph2bars(ph, dim):
    bars = np.asarray(ph[f"bars{dim}"]).T
    pers = bars[:, 1] - bars[:, 0]
    return bars[pers > 1.]

bars1 = [ph2bars(ph,1) for ph in phs]
bars2 = [ph2bars(ph,2) for ph in phs]

bars1_t = [ph2bars(ph,1) for ph in phs_t]
bars2_t = [ph2bars(ph,2) for ph in phs_t]

n = len(phs)
n_t = len(phs_t)

dists1 = np.zeros([n, n + n_t])
for i in range(n):
    print(f"{i}/{n}", end='\r')
    for j in range(i+1, n):
        dists1[i, j] = dists1[j, i] = W(bars1[i], bars1[j])
    for j in range(n_t):
        dists1[i, n+j] = W(bars1[i], bars1_t[j])

pd.DataFrame(dists1, columns=df.acc).to_csv("wassersteins1.tsv.gz", sep='\t', index=False)

dists2 = np.zeros([n, n + n_t])
for i in range(n):
    print(f"{i}/{n}", end='\r')
    for j in range(i+1, n):
        dists2[i, j] = dists2[j, i] = W(bars2[i], bars2[j])
    for j in range(n_t):
        dists2[i, n+j] = W(bars2[i], bars2_t[j])

pd.DataFrame(dists2, columns=df.acc).to_csv("wassersteins2.tsv.gz", sep='\t', index=False)


