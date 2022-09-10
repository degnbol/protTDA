#!/usr/bin/env zsh
# USE: pdb2tsv.sh < INFILE.pdb > OUTFILE.tsv
# Source: https://www.wwpdb.org/documentation/file-format-content/format33/sect9.html#ATOM
TMP=$RANDOM.tmp
grep '^ATOM' > $TMP
paste -d, \
    <(cut -c07-11 $TMP) \
    <(cut -c13-16 $TMP) \
    <(cut -c17-17 $TMP) \
    <(cut -c18-20 $TMP) \
    <(cut -c22-22 $TMP) \
    <(cut -c23-26 $TMP) \
    <(cut -c27-27 $TMP) \
    <(cut -c31-38 $TMP) \
    <(cut -c39-46 $TMP) \
    <(cut -c47-54 $TMP) \
    <(cut -c55-60 $TMP) \
    <(cut -c61-66 $TMP) \
    <(cut -c77-78 $TMP) \
    <(cut -c79-80 $TMP) |
    mlr --c2t --hi label atomi,atom,altLoc,res,chain,resi,iCode,x,y,z,occupancy,temp,element,charge +\
    clean-whitespace

