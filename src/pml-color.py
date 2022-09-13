#!/usr/bin/env python3
# USE 1: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.txt [-p PALLETE]
# USE 2: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.json [-k ENTRIES... [-p PALLETE]]
# Examples above assumes pml-color.py is in your PATH.
# values.txt has one numerical value on each line, corresponding to each residue.
# values.json has this instead inside an entry with keys nested by ENTRIES, by default structure name inside INFILE.pdb.
# pallete is one of the available ones for the spectrum command: 
# https://pymolwiki.org/index.php/Spectrum
import json
import sys
from os.path import isfile
import argparse

# We only color the first given pdb if there are multiple.
obj = cmd.get_object_list()[0]

parser = argparse.ArgumentParser(description="Color structure in pymol according to a simple file with numbers or json with similar entry.")
parser.add_argument("infile")
parser.add_argument("-k", "--keys", nargs="+", help="For json.", default=[obj])
parser.add_argument("-p", "--palette", help="Color palette. Examples on https://pymolwiki.org/index.php/Spectrum", default="rainbow")
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

# clear all B-factors so any that aren't residues will have the color 
# associated with zero rather than their actual B-factor.
cmd.alter(obj, 'b=0.0')
# update the B-factors with new properties.
# pop() instead of values[int(resi)-1] means we handle a skip in indexes (happens in T1036s1)
cmd.alter(obj + ' and name CA', 'b=values.pop()')
# color with spectrum command using default rainbow palette.
cmd.spectrum("b", args.palette, obj)

