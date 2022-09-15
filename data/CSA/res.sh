#!/usr/bin/env zsh
rcsb='$RCSB = regextract($1, "[0-9][0-9a-z]{3}")'
mb='$MB = regextract($1, "[0-9]+MB")' 
tm='$time = regextract($1, "[0-9]{2}:[0-9]{2}:[0-9]{2}")'
grep RAM log/*.log | mlr -t --hi put "$rcsb; $mb" + cut -x -f 1 + put '$H = 1' > resH1MB.tsv
grep time log/*.log | mlr -t --hi put "$rcsb; $tm" + cut -x -f 1 + put '$H = 1' > resH1time.tsv
grep RAM logH2/*.log | mlr -t --hi put "$rcsb; $mb" + cut -x -f 1 + put '$H = 2' > resH2time.tsv
grep time logH2/*.log | mlr -t --hi put "$rcsb; $tm" + cut -x -f 1 + put '$H = 2' > resH2time.tsv

mlr -t cat resH{1,2}MB.tsv > resMB.tsv
mlr -t cat resH{1,2}time.tsv > restime.tsv
mlr -t join -j RCSB,H -f res{MB,time}.tsv > res.tsv

rm resH*.tsv res{MB,time}.tsv 
