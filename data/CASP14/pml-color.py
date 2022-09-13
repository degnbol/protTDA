#!/usr/bin/env python3
import json
import numpy as np
from os.path import isfile
import sys
# external package installed in pymol with command
# import pip; pip.main(['install', 'colorcet'])
import colorcet

categorical_palette = "#d0e3f5 #712e67 #267592 #5fb12a #fac800 #ff7917 #e23a34".replace('#', '0x')
# continuous_palette = "#1f005c #6d0065 #ab0060 #dd0652 #ff513c #ff8c1a #ffc600 #ffff00".replace('#', '0x')
# https://colorcet.holoviz.org/
continuous_palette = " ".join(colorcet.bgyw).replace('#', '0x')
continuous_palette = " ".join(colorcet.bmy).replace('#', '0x')

def nonsingular(categories):
    """
    Given int vector, return int vector where each singlular unique entry is 0, 
    and the rest are categorical starting at 1.
    """
    categories = np.asarray(categories)
    out = np.zeros(len(categories), dtype=int)
    cat = 0
    for u, n in zip(*np.unique(categories, return_counts=True)):
        if n > 1:
            cat += 1
            out[categories == u] = cat
    return list(out)

def get_resis(obj):
    stored.resis = []
    cmd.iterate(obj + ' and name CA', 'stored.resis.append(int(resi))')
    return stored.resis


objs = cmd.get_object_list()
obj = objs[0]

cmd.remove("resn hoh")
cmd.set('ribbon_width', 5)
cmd.hide('cartoon', obj)
cmd.show('licorice', obj + " and backbone and not name O")
for other in objs[1:]:
    cmd.align(objs[0], other)
    cmd.hide('cartoon', other)
    cmd.color('grey40', other)

fname_comm = "communities.json"
fname_nodeCentH1 = f"nodeCentsCA/{obj}.tsv"
fname_nodeCentH2 = f"nodeCentsH2/{obj}.tsv"

with open(fname_comm) as fp:
    comms = json.load(fp)
    commH1 = comms["H1"].get(obj, None)
    commH2 = comms["H2"].get(obj, None)

if isfile(fname_nodeCentH1):
    with open(fname_nodeCentH1) as fp:
        nodeCentH1 = [float(l.strip()) for l in fp]
else:
    nodeCentH1 = None

if isfile(fname_nodeCentH2):
    with open(fname_nodeCentH2) as fp:
        nodeCentH2 = [float(l.strip()) for l in fp]
else:
    nodeCentH2 = None

valDict = dict(commH1=commH1, commH2=commH2, centH1=nodeCentH1, centH2=nodeCentH2)
if all(v is None for v in valDict.values()):
    sys.stderr.write("No community or centrality entries or files found.")
    exit()

for valName, values in valDict.items():
    if values is None: continue
    _obj = obj + '_' + valName
    cmd.copy(_obj, obj)
    cmd.alter(_obj, 'b=0')
    cmd.color('grey', _obj)
    
    resis = np.asarray(get_resis(_obj))
    
    if isinstance(values[0], float):
        palette = continuous_palette
        # if centralities are missing at the end they are zero
        values += [0]*(len(resis)-len(values))
    else:
        palette = categorical_palette
        values = nonsingular(values)
    
    values = np.asarray(values)
    def getb(resi):
        return values[resis==int(resi)][0]
    cmd.alter(_obj, 'b=getb(resi)')
    cmd.spectrum('b', palette, _obj)

cmd.disable(obj)
# cmd.save(f"colored/{obj}.pse.gz")

