#!/usr/bin/env zsh
# make a command "git root" that gives the root folder of the repo.
git config alias.root 'rev-parse --show-toplevel'
# make sure submodules of other publications are initialized.
git submodule update --init

pip install --upgrade google-cloud-storage
# assuming gcloud sdk is installed. login to the project specified in fetch.py
gcloud auth application-default login
