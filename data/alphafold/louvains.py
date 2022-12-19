#!/usr/bin/env python3
import sys
sys.path.append("../../src")
import louvain
import os
from os.path import isfile
from pathlib import Path
from random import shuffle


d1s = os.listdir("PH")
omes = [os.path.join("PH", d1, d2) for d1 in d1s for d2 in os.listdir("PH/"+d1)]
print(len(omes), " proteomes")

omes = [ome for ome in omes if not isfile(ome + "/louvain.json.gz")]
print(len(omes), " todo")

shuffle(omes)

with open("louvains.log", "a") as log:
    for outdir in omes[0:min(1000,len(omes))]:
        if isfile(outdir+"/.inprogress"): continue
        Path(outdir+"/.inprogress").touch()
        print(outdir, file=log, flush=True)
        louvain.main(outdir+'/AF*.json.gz', outdir+'/louvain.json.gz', log=log)
        os.remove(outdir+"/.inprogress")

