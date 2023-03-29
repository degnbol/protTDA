#!/usr/bin/env zsh
\ls -d PH/*/ | grep '^PH.[0-9-]*.$' | while read dir; do
    [ -d PH/MF/$dir:t ] || echo $dir;
    return
done | head -n1 | cut -f2 -d/
