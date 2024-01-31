#!/usr/bin/env zsh
mlr -t --from taxNodes.tsv stats1 -g domain -f proteins -a min,max,mean,stddev
# also just looking in the file ../postgres/treeNode_domain.tsv.gz
# with by_protein = t(rue)
