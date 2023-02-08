#!/usr/bin/env python3
# Use import.js instead, visibly faster.
# USE: import.py ../../data/alphafold/PH/100
import os, sys
from arango import ArangoClient
import gzip
import orjson
import numpy as np

client = ArangoClient(hosts="http://localhost:8529")
protTDA = client.db("protTDA", username="root", password="")

# reset
# protTDA.delete_collection("AF")
# protTDA.create_collection("AF")
AF = protTDA.collection("AF")

# d0 = "../../data/alphafold/PH/100"
# d1 = "../../data/alphafold/PH/100/100-0/"
d0 = sys.argv[1]
d1s = os.listdir(d0)

for d1 in d1s:
    d1 = d0+'/'+d1+'/'
    sys.stdout.write(d1+'\n')
    fnames = [f for f in os.listdir(d1) if f.startswith("AF")]
    N = len(fnames)

    for i, fname in enumerate(fnames):
        if i % 100 == 0: sys.stdout.write(f'{i}/{N}\r')
        with gzip.open(d1 + fname) as f:
            d = orjson.loads(f.read())
            d["_key"] = fname.split('-')[1]
            d["pers1"] = [death - birth for birth, death in zip(d["bars1"][0], d["bars1"][1])]
            d["pers2"] = [death - birth for birth, death in zip(d["bars2"][0], d["bars2"][1])]
            AF.insert(d)

    sys.stdout.write('\n')

