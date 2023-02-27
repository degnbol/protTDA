#!/usr/bin/env zsh
# Auto install didn't work
# https://dgraph.io/docs/installation/download/
wget https://github.com/dgraph-io/dgraph/releases/download/v22.0.2/dgraph-linux-arm64.tar.gz
sudo tar -C /usr/local/bin -xzf dgraph-linux-arm64.tar.gz
dgraph version # works

echo https://dgraph.io/docs/installation/single-host-setup/

# install completion for zsh. Fix that they put square brackets in text which zsh compl tries to interpret.
dgraph completion zsh | sed 's/\[cpu, mem, mutex, block\]/cpu, mem, mutex, block/' | sed 's/\[Enterprise Feature\]/(Enterprise Feature)/g' > ~/dotfiles/completions/_dgraph
