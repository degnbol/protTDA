#!/usr/bin/env zsh
sed 's,^,gs://public-datasets-deepmind-alphafold-v4/,' v4_updated_accessions.txt | sed 's,$,-model_v4.cif,' | gsutil -m cp -I ./PH/v4/model
