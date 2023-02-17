#!/usr/bin/env zsh
conda create -n dgraph python ipython
conda activate dgraph
# https://github.com/dgraph-io/pydgraph#install
pip install pydgraph
# error importing pydgraph let to a solution by downgrading a package:
# https://stackoverflow.com/questions/72441758/typeerror-descriptors-cannot-not-be-created-directly
pip install protobuf==3.20

