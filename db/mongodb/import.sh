#!/usr/bin/env zsh
# Not in use, since we need to assign accession to _id property.
FILENAME=$1
COLLECTION=$FILENAME:r:t
gunzip -c $FILENAME | mongoimport --collection $COLLECTION --type json
