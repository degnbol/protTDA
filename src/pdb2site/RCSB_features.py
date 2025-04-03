#!/usr/bin/env python3
import json, gzip
import pandas as pd
import sys, os

"""
Extract features that have been annotated by RCSB to PDB file positions.
USE: ./RCSB_features.py RCSB_features.json ...
- RCSB_features.json: A .json file downloaded with the uniprot or 
  polymer_entity_instance service from the RCSB REST.
RETURN: writes to input files with extension changed from .json to .tsv
"""

infnames = sys.argv[1:]

for infname in infnames:
    if os.path.getsize(infname) == 0:
        print("Empty file: " + infname)
        continue

    root, extension = os.path.splitext(infname)
    
    if extension == '.gz':
        root = os.path.splitext(root)[0]
        with gzip.open(infname) as infile:
            json_list = json.load(infile)
    else:
        with open(infname) as infile:
            json_list = json.load(infile)
    
    outfname = root + '.tsv'
    
    # uniprot service files contain a list of dict but the 
    # polymer_entity_instance service just has the dict.
    if isinstance(json_list, dict):
        json_list = [json_list]

    features = []

    for json_dict in json_list:
        # we can check for only one of them. 
        # They will never appear in the same file since they are generated with different services.
        if "rcsb_uniprot_feature" in json_dict:
            raw_features = json_dict["rcsb_uniprot_feature"]
        elif "rcsb_polymer_instance_feature" in json_dict:
            raw_features = json_dict["rcsb_polymer_instance_feature"]
        else:
            continue
        
        for raw_feature in raw_features:
            # explode feature_positions
            if "feature_positions" not in raw_feature: continue
            positions = raw_feature["feature_positions"]
            del raw_feature["feature_positions"]
            
            # field "additional_properties" has structure [{'name': "...", values: [...]}, ...]
            # It doesn't have values for most entry types, e.g. sites. It has duplicate sense info for sheets.
            # We should either discard it or convert it to a nicer format: dict(name=values, ...).
            if "additional_properties" in raw_feature:
                del raw_feature["additional_properties"]
            
            for position in positions:
                # If it's not a range but a single point feature, then only the start is given, no end.
                # We duplicate the end for these cases.
                if "end_seq_id" not in position:
                    position["end_seq_id"] = position["beg_seq_id"]
                feature = {**raw_feature, "start": position["beg_seq_id"], "end": position["end_seq_id"]}
                features.append(feature)
    
    if len(features) > 0:
        pd.DataFrame(features).to_csv(outfname, sep='\t', index=False)
    else:
        print("No features: " + infname)

