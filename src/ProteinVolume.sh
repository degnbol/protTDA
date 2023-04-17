#!/usr/bin/env zsh
# USAGE: src/ProteinVolume.sh PATH/TO/ProteinVolume_1.3.jar INDIR > volumes.tsv
# WHERE INDIR has *.pdb, *.cif, or *.cif.gz
# volumes.tsv will have columns Protein,SolventExcludedVolume,VanDerWaalsVolume
# Calculates solvent-excluded (and other) volumes with ProteinVolume https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-015-0531-2
# http://gmlab.bio.rpi.edu/download.php
ProteinVolume=$1
INDIR=$2

# rm previous work
# (N) to glob without error if no file is found
pdb_logs=($INDIR/OutputDir_pdbs_*.txt(N))
[ "$pdb_logs" ] && rm $pdb_logs

# number of structures
N=`ls $INDIR | wc -l | xargs`

java -jar $ProteinVolume -het --radiusFileName $ProteinVolume:h/bondi.rad $INDIR |
    tee ProteinVolume.tmp.tsv | $0:h/progress.sh "$N" 6 1>&2 # STDERR

sed '1,6d' ProteinVolume.tmp.tsv | sed $'s/   */\t/g' |
    mlr -t rename -g -r ' ,' + cut -x -f 'TimeTaken(ms)' + \
    rename 'TotalVolume(A3),SolventExcludedVolume,VDWVolume,VanDerWaalsVolume,Protein,Entry' # STDOUT

# cleanup
rm ProteinVolume.tmp.tsv
