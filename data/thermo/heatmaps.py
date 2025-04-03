#!/usr/bin/env python3
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import gzip
import orjson

sizes = {}
for fname in os.listdir("PH"):
    acc = fname.split('-')[1]
    with gzip.open("PH/" + fname) as fp:
        sizes[acc] = orjson.loads(fp.read())["n"]

ws1 = pd.read_table("./wassersteins1.tsv.gz")
ws2 = pd.read_table("./wassersteins2.tsv.gz")
ws1.set_index(ws1.columns, inplace=True)
ws2.set_index(ws2.columns, inplace=True)
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

for col in sup:
    print(col)
    sup[col].to_csv(f"super/{col}.tsv.gz", sep='\t')

df = pd.read_table("./thermozymes-acc-unjag-taxed.tsv.gz", index_col="acc")
meso = df.index[df.thermophile == 0]
thermo = df.index[df.thermophile == 1]

df = df.join(pd.DataFrame(dict(n=sizes.values()), index=sizes.keys()))
df = df[df.n > 400]
df = df.sort_values("EC")

index = np.ones(len(df.index), dtype=bool)
# index = np.asarray(df.thermophile == 0)
# index = np.asarray(df.thermophile == 1)

# sort and filter according to df
ws1s = np.asarray(ws1.loc[df.index, df.index])[index, :][:, index]
ws2s = np.asarray(ws2.loc[df.index, df.index])[index, :][:, index]
sups = {col: np.asarray(sup[col].loc[df.index, df.index])[index, :][:, index] for col in sup}

ecs = np.asarray([[int(v) for v in ec.split(".")] for ec in df.EC[index]])
ecs_sq = np.hstack([np.repeat(ecs[:,[i]], sum(index) / 4, axis=1) for i in range(4)])


vmax = ws2.max().max()

ax1 = plt.subplot(131)
mp1 = plt.imshow(ecs_sq)
plt.colorbar(mp1, ax=ax1)
ax2 = plt.subplot(132)
mp2 = plt.imshow(ws1s, vmax=2)
ax2.set_title("H1 wasserstein")
plt.colorbar(mp2, ax=ax2)
ax3 = plt.subplot(133)
mp3 = plt.imshow(ws2s, vmax=2)
ax3.set_title("H2 wasserstein")
plt.colorbar(mp3, ax=ax3)
plt.show()

ax1 = plt.subplot(1, len(sup)+1, 1)
plt.imshow(ecs_sq)
for i, (k, s) in enumerate(sups.items()):
    ax = plt.subplot(1, len(sup)+1, i+2)
    plt.imshow(s)
    ax.set_title(k)
plt.show()

idx = df.EC == "1.1.1.44"

ws2_44 = ws2s[idx][ws2s.columns[idx]]
ws2_n44 = ws2s[idx][ws2s.columns[~idx]]

print(np.max(np.asarray(ws2_44)))
print(np.max(np.asarray(ws2_n44)))
print(np.mean(np.asarray(ws2_44)))
print(np.mean(np.asarray(ws2_n44)))
print(np.median(np.asarray(ws2_44)))
print(np.median(np.asarray(ws2_n44)))

ax1 = plt.subplot(131)
mp1 = plt.imshow(ws2_44, vmin=0, vmax=vmax, cmap="pink")
plt.colorbar(mp1, ax=ax1)
ax2 = plt.subplot(132)
mp2 = plt.imshow(ws2_n44, vmin=0, vmax=vmax, cmap="pink")
plt.colorbar(mp2, ax=ax2)
ax3 = plt.subplot(133)
mp3 = plt.imshow(np.hstack([ws2_44, ws2_n44]), vmin=0, vmax=vmax, cmap="pink")
plt.colorbar(mp3, ax=ax3)
plt.show()

