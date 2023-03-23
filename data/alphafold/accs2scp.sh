#!/usr/bin/env zsh
# USE: ./accs2scp.sh [OUTDIR] < ACC
# where ACC has one accession written on each line.
# OR: echo F2YQ03 | ./accs2scp.sh [OUTDIR]
OUTDIR=${1:=$PWD}
[ -d $OUTDIR ] || mkdir $OUTDIR

remote='opc@168.138.0.242'

cat - | ssh $remote 'cd $HOME/protTDA/data/alphafold; ./accs2paths.jl' | mlr -t uniq -f path | sed 1d | while read fname; do
    scp "$remote:~/protTDA/data/alphafold/$fname" $OUTDIR/$fname:t
done
