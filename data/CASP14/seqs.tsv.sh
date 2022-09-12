#!/usr/bin/env zsh
tr -d '\n' < raw/casp14.faa | tr '>' '\n' | sed '/^$/d' | tr '|' '\t' | sed -E 's/ +/\t/' | sed -E 's/, ([0-9]+) residues/\t\1/' | sed 's/,/\t/' |
    mlr -t label casp14,gene,description,length,aa + put '$subunit = sub(regextract_or_else($description, "subunit [0-9]+", ""), "subunit ", "")' +\
    put '$species = sub($description, ", subunit.*", "")' + clean-whitespace +\
    put 'if (strlen($description) > 0) {$range = sub(regextract_or_else($description, "residues [0-9]+-[0-9]+", ""), "[a-z]* ", "")} else {$range = ""}' +\
    put '$species = sub($species, "residues [0-9]+-[0-9]+, ", "")' + put '$species = sub($species, "Q9BXU0, ", "")' +\
    cut -x -f description + reorder -e -f aa > seqs.tsv
