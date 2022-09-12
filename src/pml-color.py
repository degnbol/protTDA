#!/usr/bin/env python3
# Color structure in pymol according to a simple file with numbers or json with similar entry.
# USE 1: pymol INFILE.pdb pml-color.py -- values.txt
# USE 2: pymol INFILE.pdb pml-color.py -- values.json entry
# Examples above assumes pml-color.py is in your PATH.
# values.txt has one numerical value on each line, corresponding to each residue.
# values.json has this instead inside an entry with key "entry".
import json
import sys

args = sys.argv[1:]

if len(args) == 1:
    infile = args[0]
    assert not infile.endswith(".json"), "pml-color.py: Json requires entry specified."
    with open(infile) as fp:
        values = [l.strip() for l in fp]
if len(args) == 2:
    infile, entry = args
    assert infile.endswith(".json"), "pml-color.py: Wrong fileformat given given."
    with open(infile) as fp:
        values = json.load(fp)[entry]
else:
    raise ValueError("pml-color.py: Specify file with values.")

def getb(resi):
    # 1-indexed -> 0-indexed with -1
    return values[int(resi)-1]

# clear all B-factors to be safe.
cmd.alter('all', 'b=0.0')
# update the B-factors with new properties.
cmd.alter('name CA', 'b=getb(resi)')
# color with spectrum command using default rainbow palette.
cmd.spectrum("b")

