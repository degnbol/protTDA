#!/usr/bin/env zsh
cd $0:h
./raw.sh
./xyz.sh
./xyzCA.sh
[ -d PH ] || echo "Complete PH calcs then ./post-PH.sh"
./unpack.sh
