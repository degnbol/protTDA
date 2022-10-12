#!/usr/bin/env zsh
# history of how files were generated as an example usage.
/usr/bin/time -l julia -t 8 `git root`/src/ripsererGen.jl xyz -H -d 2 -α -o ripsererH2/
