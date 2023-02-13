#!/usr/bin/env zsh
# Auto install didn't work
# https://dgraph.io/docs/installation/download/
wget https://github.com/dgraph-io/dgraph/releases/download/v22.0.2/dgraph-linux-arm64.tar.gz
sudo tar -C /usr/local/bin -xzf dgraph-linux-arm64.tar.gz
dgraph version # works

echo https://dgraph.io/docs/installation/single-host-setup/
