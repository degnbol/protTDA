#!/usr/bin/env python3
# USE: fetchseqs.py < INFILE > OUTFILE.tsv
# where infile has 1 accession on each line.
# https://github.com/RDFLib/sparqlwrapper
# installed with conda
from SPARQLWrapper import SPARQLWrapper, CSV
import sys

accs = [l.rstrip() for l in sys.stdin]

nBatch = 300
for i in range(0, len(accs), nBatch):
    sys.stderr.write(f"{i}/{len(accs)}\n")
    accs_batch = accs[i:(i+nBatch)]

    accs_str = ' '.join([f'("{a}")' for a in accs_batch])

    sparql = SPARQLWrapper("https://sparql.uniprot.org/sparql")
    sparql.setReturnFormat(CSV)

    sparql.setQuery("""
    PREFIX up: <http://purl.uniprot.org/core/>
    PREFIX uniprotkb: <http://purl.uniprot.org/uniprot/>
    SELECT ?ac ?seq
    WHERE {
      VALUES (?ac) {""" + accs_str + """ }
      BIND (IRI(CONCAT("http://purl.uniprot.org/uniprot/",?ac)) AS ?protein)
      ?protein a up:Protein .
      ?protein up:sequence ?seqs .
      ?seqs rdf:value ?seq .
    }
    """)

    ret = sparql.queryAndConvert()
    s = '\n'.join(ret.decode().split('\n')[1:]).replace('"', '').replace(',', '\t')
    sys.stdout.write(s)
    sys.stdout.flush()

