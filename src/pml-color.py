#!/usr/bin/env python3
# USE 1: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.txt
# USE 2: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.json [-k ENTRIES...]
# Examples above assumes pml-color.py is in your PATH.
# values.txt has one numerical value on each line, corresponding to each residue.
# values.json has this instead inside an entry with keys nested by ENTRIES, by default structure name inside INFILE.pdb.
# pallete is one of the available ones for the spectrum command: 
# https://pymolwiki.org/index.php/Spectrum
import json
import sys
from os.path import isfile
import argparse
try: import colorcet
except ModuleNotFoundError: # a little convenience
    import pip; pip.main(['install', 'colorcet'])
    import colorcet

categorical_palette = "#d0e3f5 #712e67 #267592 #5fb12a #fac800 #ff7917 #e23a34".replace('#', '0x')
# continuous_palette = "#1f005c #6d0065 #ab0060 #dd0652 #ff513c #ff8c1a #ffc600 #ffff00".replace('#', '0x')
# https://colorcet.holoviz.org/
# continuous_palette = " ".join(colorcet.bgyw).replace('#', '0x')
continuous_palette = " ".join(colorcet.bmy).replace('#', '0x')

# We only color the first given pdb if there are multiple.
obj = cmd.get_object_list()[0]

parser = argparse.ArgumentParser(description="Color structure in pymol according to a simple file with numbers or json with similar entry.")
parser.add_argument("infile")
parser.add_argument("-k", "--keys", nargs="+", help="For json.", default=[obj])
args = parser.parse_args()

if args.infile.endswith(".json"):
    with open(args.infile) as fp:
        if args.infile.endswith(".json"):
            values = json.load(fp)
            for k in args.keys: values = values[k]
else:
    with open(args.infile) as fp:
        values = [l.strip() for l in fp]
    # parse so if values are float then don't treat them as categorical
    # Parsing is automatically done for json.
    try: values = [int(v) for v in values]
    except ValueError:
        try: values = [float(v) for v in values]
        except ValueError: pass


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

cmd.remove("resn hoh") # remove water
cmd.set('ribbon_width', 5, obj) # more visible ribon
cmd.hide('cartoon', obj)
# custom backbone visualisation
cmd.show('licorice', obj + " and backbone and not name O")

# clear all B-factors so any that aren't residues will have the color 
# associated with zero rather than their actual B-factor.
cmd.alter(obj, 'b=0')
cmd.color('grey', obj)

resis = np.asarray(get_resis(obj))

if isinstance(values[0], float):
    palette = continuous_palette
    # if values (centralities) are missing at the end they are zero
    values += [0]*(len(resis)-len(values))
else:
    palette = categorical_palette
    values = nonsingular(values)

values = np.asarray(values)
def getb(resi):
    return values[resis==int(resi)][0]
cmd.alter(obj, 'b=getb(resi)')
cmd.spectrum('b', palette, obj)

