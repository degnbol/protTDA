COPY treenode TO '/home/opc/protTDA/data/alphafold/postgres/treeNode.tsv' DELIMITER E'\t' CSV HEADER;
COPY treenode_perprot TO '/home/opc/protTDA/data/alphafold/postgres/treeNode_perProt.tsv' DELIMITER E'\t' CSV HEADER;
COPY treeedge TO '/home/opc/protTDA/data/alphafold/postgres/treeEdge.tsv' DELIMITER E'\t' CSV HEADER;
COPY treeedge_perprot TO '/home/opc/protTDA/data/alphafold/postgres/treeEdge_perProt.tsv' DELIMITER E'\t' CSV HEADER;
