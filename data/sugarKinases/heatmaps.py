#!/usr/bin/env python3
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import gzip
import orjson

ws1 = pd.read_table("./wassersteins1.tsv.gz")
ws2 = pd.read_table("./wassersteins2.tsv.gz")
ws1.set_index(ws1.columns[:len(ws1)], inplace=True)
ws2.set_index(ws2.columns[:len(ws2)], inplace=True)
assert all(ws1.index == ws2.index)

supers = pd.read_table("./supers.tsv.gz")
supers.i = [fname.split('-')[1] for fname in supers.i]
supers.j = [fname.split('-')[1] for fname in supers.j]

sup = {}
for col in set(supers.columns) - {"i", "j", "cycles"}:
    print(col)
    uptri = supers.pivot(index="i", columns="j", values=col)
    lotri = supers.pivot(index="j", columns="i", values=col)
    # diagonal is not calculated but is 0 distance or for cols that aren't distance just ignore it.
    sup[col] = uptri.combine_first(lotri).fillna(0)
    sup[col].rename_axis("acc", inplace=True)

# for col in sup:
#     print(col)
#     sup[col].to_csv(f"super/{col}.tsv.gz", sep='\t')

df = pd.read_table("bork1992_table1-unjag-uniprot-category.tsv", index_col="Entry")

ecs = ["ec1", "ec2", "ec3", "ec4"]

df[ecs] = np.asarray([[int(v) for v in ec.split(".")] for ec in df.EC])
df = df.sort_values(ecs)
ecs_sq = np.hstack([np.repeat(np.reshape(np.asarray(df[f"ec{i+1}"]), [-1, 1]), np.ceil(len(df) / 4), axis=1) for i in range(4)])

# sort and filter according to df
rowidx = list(df.index)
colidx = set(ws1.columns) - set(ws1.index)
for _, s in sup.items():
    colidx = colidx.intersection(s.columns)
colidx = rowidx + list(colidx)
ws1s = np.asarray(ws1.loc[rowidx, colidx])
ws2s = np.asarray(ws2.loc[rowidx, colidx])
sups = {col: np.asarray(sup[col].loc[rowidx, colidx]) for col in sup}

vmax = ws2.max().max()
ncl = len(sup)+2

# ax1 = plt.subplot(2, ncl, 1)
# mp1 = plt.imshow(ecs_sq)
# plt.colorbar(mp1, ax=ax1)
ax2 = plt.subplot(ncl, 1, 1)
mp2 = plt.imshow(ws1s, cmap="pink", vmax=2)
ax2.set_title("H1 wasserstein")
# plt.colorbar(mp2, ax=ax2)
ax3 = plt.subplot(ncl, 1, 2)
mp3 = plt.imshow(ws2s, cmap="pink", vmax=2)
ax3.set_title("H2 wasserstein")
# plt.colorbar(mp3, ax=ax3)
# ax1 = plt.subplot(2, ncl, ncl+1)
# plt.imshow(ecs_sq)
for i, (k, s) in enumerate(sups.items()):
    ax = plt.subplot(ncl, 1, i+3)
    plt.imshow(s, cmap="pink")
    ax.set_title(k)
plt.tight_layout()
plt.show()

def sugarkinase_part(mat):
    return np.asarray([mat[i,j] for i,j in zip(*np.tril_indices(mat.shape[0], k=-1))])

def unrelated_part(mat):
    return mat[:, mat.shape[0]:].flatten()

sugarkinases1 = sugarkinase_part(ws1s)
sugarkinases2 = sugarkinase_part(ws2s)
unrelated1 = unrelated_part(ws1s)
unrelated2 = unrelated_part(ws2s)
sugarkinasesRMSD = sugarkinase_part(sups["RMSD_post"])
unrelatedRMSD = unrelated_part(sups["RMSD_post"])

ax = plt.subplot(2, 3, 1)
ax.set_title("wasserstein H1")
ax.set_ylabel("sugar kinases vs. sugar kinases")
plt.hist(sugarkinases1, bins=50, range=[0, unrelated1.max()])
ax = plt.subplot(2, 3, 4)
ax.set_ylabel("sugar kinases vs. unrelated")
plt.hist(unrelated1, bins=50, range=[0, unrelated1.max()])
ax = plt.subplot(2, 3, 2)
ax.set_title("wasserstein H2")
plt.hist(sugarkinases2, bins=50, range=[0, unrelated2.max()])
ax = plt.subplot(2, 3, 5)
plt.hist(unrelated2, bins=50, range=[0, unrelated2.max()])
ax = plt.subplot(2, 3, 3)
ax.set_title("RMSD")
plt.hist(sugarkinasesRMSD, bins=50, range=[0, unrelatedRMSD.max()])
ax = plt.subplot(2, 3, 6)
plt.hist(unrelatedRMSD, bins=50, range=[0, unrelatedRMSD.max()])
plt.show()

