#!/usr/bin/env zsh
# first this was tried:
mlr --ho -t --from thermozymes.tsv cut -f EC | sort -u | grep -v '-' | ./ec2acc.sh | wc -l
# it only gives ~1600 accessions since they are all reviewed (swiss prot).
# we use the following search criteria on uniprot:
mlr --ho -t --from thermozymes.tsv cut -f EC | sort -u | grep -v '-' | sed 's/^/(ec:/' | sed 's/$/) OR/' | tr '\n' ' '
# they were then downloaded both as tsv and as list of accessions.
