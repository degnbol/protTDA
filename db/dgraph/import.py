#!/usr/bin/env python3
import os
import orjson, gzip
import pydgraph
import time

client_stub = pydgraph.DgraphClientStub('localhost:9080')
client = pydgraph.DgraphClient(client_stub)

# Drop all data including schema from the Dgraph instance. This is a useful
# for small examples such as this since it puts Dgraph into a clean state.
op = pydgraph.Operation(drop_all=True)
client.alter(op)

schema = """
x: float .
y: float .
z: float .
cent1: float .
cent2: float .
type Ca {
    x: Float!
    y: Float!
    z: Float!
    cent1: Float!
    cent2: Float!
}
v1: uid .
v2: uid .
v3: uid .
type Simplex1 {
    v1: Ca!
    v2: Ca!
}
type Simplex2 {
    v1: Ca!
    v2: Ca!
    v3: Ca!
}
birth: float .
death: float .
persistence: float @index(float) .
simplices: [uid] @count .
type Rep1 {
    birth: Float!
    death: Float!
    persistence: Float!
    simplices: [Simplex1!]!
}
type Rep2 {
    birth: Float!
    death: Float!
    persistence: Float!
    simplices: [Simplex2!]!
}
acc: string @index(exact) .
n: int @index(int) .
cas: [uid] @count .
reps1: [uid] @count .
reps2: [uid] @count .
type AFProt {
    acc: String!
    n: Int!
    cas: [Ca!]!
    reps1: [Rep1!]!
    reps2: [Rep2!]!
}
"""
op = pydgraph.Operation(schema=schema)
client.alter(op)

before = time.time()

fname = "/home/opc/protTDA/data/alphafold/PH/100/100-0/AF-A0A3S0EAG4-F1-model_v3.json.gz"
acc = os.path.basename(fname).split('-')[1]

with gzip.open(fname) as fh:
    PH = orjson.loads(fh.read())

txn = client.txn()

cas = []
for x, y, z, cent1, cent2 in zip(PH["x"], PH["y"], PH["z"], PH["cent1"], PH["cent2"]):
    cas.append({'dgraph.type': "Ca", 'x':x, 'y':y, 'z':z, 'cent1':cent1, 'cent2':cent2})

res = txn.mutate(set_obj=cas)
cas = [dict(uid=i) for i in res.uids.values()]

reps1 = []
for birth, death, rep in zip(PH["bars1"][0], PH["bars1"][1], PH["reps1"]):
    # minus one for 1 to 0 indexing conversion.
    simplices = [{'dgraph.type':"Simplex1", '1': cas[simplex[0]-1], '2': cas[simplex[1]-1]} for simplex in rep]
    reps1.append({'dgraph.type':"Rep1", 'birth':birth, 'death':death, 'persistence':death-birth, 'simplices':simplices})

reps2 = []
for birth, death, rep in zip(PH["bars2"][0], PH["bars2"][1], PH["reps2"]):
    # minus one for 1 to 0 indexing conversion.
    simplices = [{'dgraph.type':"Simplex2", '1': cas[simplex[0]-1], '2': cas[simplex[1]-1], '3': cas[simplex[2]-1]} for simplex in rep]
    reps2.append({'dgraph.type':"Rep2", 'birth':birth, 'death':death, 'persistence':death-birth, 'simplices':simplices})

prot = {'dgraph.type':"AFProt", 'acc':acc, 'n':PH["n"], 'cas':cas, 'reps1':reps1, 'reps2':reps2}
res = txn.mutate(set_obj=prot)
len(res.uids.values())
txn.commit()
txn.discard()

after = time.time()
print(after - before)

# debug:
nNodes = 1 + len(cas) + len(reps1) + len(reps2) + sum(len(r) for r in reps1) + sum(len(r) for r in reps2)
nNodes


def q(query, variables=dict()):
    txn = client.txn()
    res = txn.query(query, variables)
    o = orjson.loads(res.json)["me"]
    txn.discard()
    return o

def qn(query):
    return len(q(query))

q("""query all($a: string) {
   me(func: eq(acc, $a)) {
      uid, acc, n
      dgraph.type
    }
  }""",
variables = {'$a': 'A0A3S0EAG4'})

q("""query {
  me(func: eq(dgraph.type, Ca)) {
    uid, x
  }
}
""")

q("""query {
  me(func: eq(dgraph.type, AFProt)) {
    uid
  }
}
""")

qn("""query {
  me(func: eq(dgraph.type, Simplex1)) {
    uid
  }
}
""")

qn("""query {
  me(func: eq(dgraph.type, Simplex2)) {
    uid
  }
}
""")

q("""query {
  me(func: eq(dgraph.type, Rep1))
     @filter(gt(persistence, 8.0)) {
    uid
    persistence
    simplices (first:4) {
        uid
    }
  }
}
""")

q("""query {
  me(func: gt(persistence, 5.0)) {
    uid
    persistence
    simplices (first:4) {
        uid
    }
  }
}
""")

qn("""query {
  me(func: eq(dgraph.type, Rep2)) {
    uid
  }
}
""")

q("""query {
  me(func: has(dgraph.type)) {
    uid
    dgraph.type
  }
}
""")



