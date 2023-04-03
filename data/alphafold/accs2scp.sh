#!/usr/bin/env zsh
# USE: ./accs2scp.sh [OUTDIR] < ACC
# where ACC has one accession written on each line.
# OR: echo F2YQ03 | ./accs2scp.sh [OUTDIR]
OUTDIR=${1:=$PWD}
[ -d $OUTDIR ] || mkdir $OUTDIR

remote='opc@168.138.0.242'

cat - | ssh $remote 'cd $HOME/protTDA/data/alphafold; ./accs2paths.jl | mlr -t uniq -f path | sed 1d | xargs tar cf download.tar'
scp "$remote:~/protTDA/data/alphafold/download.tar" download.tar
tar xf download.tar --strip-components=3 -C $OUTDIR && rm download.tar
ssh $remote 'rm $HOME/protTDA/data/alphafold/download.tar'

