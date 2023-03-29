#!/usr/bin/env python3
import sys, os
import orjson, gzip
from faunadb import query as q
from faunadb.objects import Ref
from faunadb.client import FaunaClient

client = FaunaClient(
  secret = "fnAE93N2MvACAAV0gxr_W2nT6YiC5QgGmuOXwjpx",
  domain = "localhost",
  port   = 8443,
  scheme = "http",
)

# check if we are good
# client.ping()

"Untested."
def clear(client):
    client.query(q.delete(client.query(q.collections())))

coll = client.query(q.create_collection({"name":"AFProt"}))

d0 = "/home/opc/protTDA/data/alphafold/PH/100"
d1 = os.path.join(d0, os.listdir(d0)[0])

# takes 1.23 seconds for 6 files which may result in 5 days upload.
for fname in os.listdir(d1):
    if not fname.startswith("AF"): continue
    print(fname)
    path = os.path.join(d1, fname)
    acc = os.path.basename(path).split('-')[1]

    with gzip.open(path) as fh:
        d = orjson.loads(fh.read())
        d["acc"] = acc

    doc = client.query(q.create(coll["ref"], d))

