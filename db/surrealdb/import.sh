#!/usr/bin/env zsh
./surreal import -u root -p root --ns testNS --db testDB --conn http://localhost:8000 ${=@}
