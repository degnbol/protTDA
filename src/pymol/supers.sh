#!/usr/bin/env zsh
# Calls to super.sh for each unique pair of files given as positional args.
# USE: src/supers.sh FILE1 FILE2 ... > OUTFILE.tsv
echo "A\tB\tRMSD_post\tatoms_post\tcycles\tRMSD_pre\tatoms_pre\traw\tres_align"
let lasti=#-1
for i in {1..$lasti}; do
    let j=i+1
    for j in {$j..$#}; do
        filei=$@[i]
        filej=$@[j]
        $0:h/super.sh $filei $filej
    done
done

