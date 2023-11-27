#!/usr/bin/env zsh
# make a command "git root" that gives the root folder of the repo.
git config alias.root 'rev-parse --show-toplevel'
# make sure submodules of other publications are initialized.
git submodule update --init --recursive

# rust was installed with rustup (the recommended way):
# https://www.rust-lang.org/tools/install
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# get python function gitpath.root()
# pip install git+https://github.com/maxnoe/python-gitpath
