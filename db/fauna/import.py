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

d0 = "/home/opc/protTDA/data/alphafold/PH/100"
d1 = os.path.join(d0, os.listdir(d0)[0])
fname = os.path.join(d1, os.listdir(d1)[0])

with gzip.open(fname) as fh:
    d = orjson.loads(fh.read())

coll = client.query(q.create_collection({"name":"AFProt"}))
doc  = client.query(q.create(coll["ref"], {"data":{"x": 0}}))

