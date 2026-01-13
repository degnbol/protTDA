# USE 1: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.txt
# USE 2: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.json [-k ENTRIES...]
# USE 3: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.tsv -c COLUMN
# USE 4: pymol INFILE.pdb [OTHER.pdb ...] pml-color.py -- values.csv -c COLUMN
# Examples above assumes pml-color.py is in your PATH.
# values.txt has one numerical value on each line, corresponding to each residue.
# values.json has this instead inside an entry with keys nested by ENTRIES, by default structure name inside INFILE.pdb.
# values.tsv/.csv has a header row, use -c to specify which column to read.
# pallete is one of the available ones for the spectrum command:
# https://pymolwiki.org/index.php/Spectrum
from pymol import cmd
import json
import argparse
import numpy as np
import colorcet


categorical_palette = "#d0e3f5 #712e67 #267592 #5fb12a #fac800 #ff7917 #e23a34".replace('#', '0x')
# Custom palettes
custom_palettes = {
    "gray_fire": "#808080 #b03000 #e05000 #ff8000 #ffa500 #ffff00",  # gray -> red -> orange -> yellow
}
# https://colorcet.holoviz.org/

# We only color the first given pdb if there are multiple.
obj = cmd.get_object_list()[0]

parser = argparse.ArgumentParser(description="Color structure in pymol according to a simple file with numbers or json with similar entry.")
parser.add_argument("infile")
parser.add_argument("-k", "--keys", nargs="+", help="For json.", default=[obj])
parser.add_argument("-c", "--column", help="Column name for TSV/CSV files (required for tabular files).")
parser.add_argument("-f", "--filter", type=float, metavar="THRESHOLD", help="Hide residues with b_factor below threshold.")
parser.add_argument("-p", "--palette", default="bmy", help="Colorcet palette name for continuous values (default: bmy). Try 'kr' for gray-to-red.")
args = parser.parse_args()

if args.infile.endswith(".json"):
    with open(args.infile) as fp:
        values = json.load(fp)
        for k in args.keys: values = values[k]
elif args.infile.endswith(".tsv") or args.infile.endswith(".csv"):
    if not args.column:
        raise ValueError("Column name required for TSV/CSV files. Use -c COLUMN.")
    delim = '\t' if args.infile.endswith(".tsv") else ','
    with open(args.infile) as fp:
        lines = [l.strip().split(delim) for l in fp]
    header = lines[0]
    col_idx = header.index(args.column)
    values = [row[col_idx] for row in lines[1:]]
    # Parse values
    try: values = [int(v) for v in values]
    except ValueError:
        try: values = [float(v) for v in values]
        except ValueError: pass
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
    Given int vector, return int vector where each singular unique entry is 0,
    and the rest are categorical starting at 1, ordered by first occurrence.
    """
    categories = np.asarray(categories)
    # Find singletons
    unique, counts = np.unique(categories, return_counts=True)
    singletons = set(unique[counts == 1])
    # Relabel by first occurrence order
    out = np.zeros(len(categories), dtype=int)
    seen = {}
    cat = 0
    for i, c in enumerate(categories):
        if c in singletons:
            continue
        if c not in seen:
            cat += 1
            seen[c] = cat
        out[i] = seen[c]
    return list(out)

def get_resis(obj):
    stored.resis = []
    cmd.iterate(obj + ' and name CA', 'stored.resis.append(int(resi))')
    return stored.resis

cmd.remove("resn hoh") # remove water
if args.filter is not None:
    cmd.hide("everything", f"b < {args.filter}")  # hide low-confidence residues
cmd.set('ribbon_width', 5, obj) # more visible ribbon
# cmd.hide('cartoon', obj)
# # custom backbone visualisation
# cmd.show('licorice', obj + " and backbone and not name O")

# clear all B-factors so any that aren't residues will have the color 
# associated with zero rather than their actual B-factor.
cmd.alter(obj, 'b=0')

resis = np.asarray(get_resis(obj))

if isinstance(values[0], float):
    # Get palette from custom or colorcet
    if args.palette in custom_palettes:
        palette = custom_palettes[args.palette].replace('#', '0x')
    else:
        palette = " ".join(getattr(colorcet, args.palette)).replace('#', '0x')
    # if values (centralities) are missing at the end they are zero
    values += [0]*(len(resis)-len(values))
else:
    palette = categorical_palette
    values = nonsingular(values)

values = np.asarray(values)
def getb(resi):
    return values[resis==int(resi)][0]
cmd.alter(obj, 'b=getb(resi)')

cmd.color('grey', obj)
cmd.spectrum('b', palette, obj)

