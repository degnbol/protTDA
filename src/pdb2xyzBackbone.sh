#!/usr/bin/env zsh
backbone='$atom == "N" || $atom == "CA" || $atom == "C" || $atom == "O"'
$0:h/pdb2tsv.sh | mlr -t filter $backbone + cut -f x,y,z,resi,atomi,atom,chain
