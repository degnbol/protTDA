#!/usr/bin/env zsh
# The most recent uniclust is from 2018 and is also the version used in alphafold (see their article)
# https://gwdu111.gwdg.de/~compbiol/uniclust/2018_08/
wget https://gwdu111.gwdg.de/~compbiol/uniclust/2018_08/uniclust30_2018_08.tar.gz
tar xzf uniclust30_2018_08.tar.gz && rm uniclust30_2018_08.tar.gz
# or just the main file:
# tar xzf uniclust30_2018_08.tar.gz uniclust30_2018_08.tsv.gz
csv2arrow -m 2 -d $'\t' --header false uniclust30_2018_08/uniclust30_2018_08.tsv.gz uniclust30.arrow
# note that lz4 on an arrow file is different from lz4 in the arrow.jl write call.
lz4 uniclust30.arrow && rm uniclust30.arrow
gzip uniclust30_2018_08/*.fasta
mv uniclust30_2018_08/* . && rmdir uniclust30_2018_08
# rm uniclust30_2018_08.tsv
