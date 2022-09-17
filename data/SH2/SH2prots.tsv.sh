#!/usr/bin/env zsh
cd $0:h
`git root`/src/table_unjag.sh 10 $'\t' 'DOMAIN ' < uniprot_16sep2022.tsv |
    mlr -t rename 'Domain [FT],domain' + filter '$domain != ""' +\
    put '$domain =~ "^([0-9]+)"; $domainStart="\1"' +\
    put '$domain =~ "^[0-9]+\.\.([0-9]+)"; $domainStop="\1"' +\
    put '$domain =~ "/note=\"([^\"]*)\""; $note="\1"' +\
    put '$domain =~ "/evidence=\"([^\"]*)\""; $evidence="\1"' +\
    cut -x -f domain +\
    filter '$note =~ "^SH2"' > SH2prots.tsv

