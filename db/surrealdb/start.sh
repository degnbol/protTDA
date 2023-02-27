#!/usr/bin/env zsh
cd $0:h
# username and password has to be set explicitly
./surreal start -u root -p root file://$PWD/db
