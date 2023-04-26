#!/usr/bin/env zsh
# https://github.com/deepmind/alphafold/blob/main/afdb/README.md
# gsutil and gcloud commands installed as part of google-cloud-cli:
# https://cloud.google.com/storage/docs/gsutil_install#linux
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-425.0.0-linux-arm.tar.gz
# follow link from:
gcloud init
# install crcmod since it is recommended for more speed
gsutil help crcmod
pip3 install --no-cache-dir -U crcmod
# see that it is set to true
gsutil version -l | grep crcmod
# otherwise make sure to install with the pip associated with the python listed at
gsutil version -l | grep python
# in tmux downloaded with 
gsutil -m cp -r gs://public-datasets-deepmind-alphafold-v4/proteomes/ .
