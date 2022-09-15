#!/usr/bin/env zsh
$0:h/pdb2tsv.sh | mlr -t filter '$atom == "CA"' + cut -f x,y,z,resi,chain
