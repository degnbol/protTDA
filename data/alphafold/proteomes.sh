#!/usr/bin/env zsh
# https://github.com/deepmind/alphafold/blob/main/afdb/README.md
# gsutil and gcloud commands installed as part of google-cloud-cli:
# https://cloud.google.com/storage/docs/gsutil_install#linux
# follow link from:
gcloud init
# install crcmod since it is recommended for more speed
gsutil help crcmod
pip3 install --no-cache-dir -U crcmod
# see that it is set to true
gsutil version -l
# in tmux downloaded with 
gsutil -m cp -r gs://public-datasets-deepmind-alphafold/proteomes/ .
