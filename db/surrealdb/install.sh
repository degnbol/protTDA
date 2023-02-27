#!/usr/bin/env zsh

curl --proto '=https' --tlsv1.2 -sSf https://install.surrealdb.com > installer.sh
chmod +x installer.sh
./installer.sh $PWD
rm installer.sh

cp _surreal ~/dotfiles/completions/

