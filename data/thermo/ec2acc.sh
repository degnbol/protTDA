#!/usr/bin/env zsh
# USE: echo 4.1.2.13 | ./ec2acc.sh
# USE: ./ec2acc.sh < INFILE.ec > OUTFILE.acc
while read EC; do
    curl https://enzyme.expasy.org/EC/$EC.txt | grep '^DR' | cut -c4- | tr ';' '\n' | cut -c3- | sed '/^$/d' | sed 's/,.*//'
done
