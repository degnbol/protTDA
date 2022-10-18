#!/usr/bin/env zsh
# https://github.com/deepmind/alphafold/blob/main/afdb/README.md
# in tmux downloaded with 
gsutil -m cp -r gs://public-datasets-deepmind-alphafold/proteomes/ .
# then untared with
\ls -f | while read file; do
    if [[ "$file:e" == "tar" ]]; then
        tar -xf $file && rm $file
    fi
done

