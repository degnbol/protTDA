#!/usr/bin/env zsh
# Instead of printing stdout, pipe it into this script and see progress.
# USAGE: CMD | progress.sh N [SKIP] 1>&2 
# N = total number of lines
# SKIP = number of initial lines to skip
# 1>&2 to print to stderr instead of default stdout
N=$1
SKIP=$2 # may be empty

# print 0/N with right adjusted 0
printf "%${#N}d/$N " 0

if [ -n "$SKIP" ]; then
    # skip SKIP lines
    for i in {1..$SKIP}; do
        read line
    done
fi

for i in {1..$N}; do
    read line
    # exit on eof (altho also on any other empty line)
    if [ -z "$line" ]; then
        break
    fi
    
    # print progress as a fraction that replaces the line (\r)
    # and i is width adjusted base on N
    printf "\r%${#N}d/$N " $i
    # calculate number of columns of progress symbol to draw
    let cols='(COLUMNS - 2 - 2*'$#N')*i/N'
    # a hacky method to repeat print a character, here "#"
    printf '%0.1s' "#"{1..$cols}
done

# clear
printf '\33[2K\r'

