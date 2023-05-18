#!/usr/bin/env node
const fs = require('fs');
const dgraph = require("dgraph-js");
const grpc = require("grpc");
const zlib = require("fast-zlib");
const simdjson = require('simdjson');

// Create data using JSON.
async function createData(dgraphClient, d) {
    // Create a new transaction.
    const txn = dgraphClient.newTxn();
    try {
        // Run mutation.
        const mu = new dgraph.Mutation();
        mu.setSetJson(d);
        const response = await txn.mutate(mu);
        const UIDs = response.array[11].map((vals, i) => {return {uid: vals[1]}});

        // Commit transaction.
        await txn.commit();
        return UIDs;
    } finally {
        // Clean up. Calling this after txn.commit() is a no-op
        // and hence safe.
        await txn.discard();
    }
}

async function main() {
    
    // const path = '/home/opc/protTDA/data/alphafold/PH/100/100-0/AF-A0A3S0EAG4-F1-model_v3.json.gz';
    const dir = '/home/opc/protTDA/data/alphafold/PH/100/100-0/';
    const fnames = fs.readdirSync(dir).slice(0, 40);
    
    const gunzip = new zlib.Gunzip();
    const clientStub = new dgraph.DgraphClientStub();
    const dgraphClient = new dgraph.DgraphClient(clientStub);
    
    const before = Date.now();

    for (const fname of fnames) {
        if (fname.startsWith("AF"))
        fs.readFile(dir + '/' + fname, (err, buf) => {
            const PH = simdjson.parse(gunzip.process(buf).toString());
        
            const cas = PH.x.map((x, i) => {
                return {'dgraph.type': "Ca", x: x, y: PH.y[i], z: PH.z[i], cent1: PH.cent1[i], cent2: PH.cent2[i]};
            });
        
            createData(dgraphClient, cas).then((cas) => {
        
                const reps1 = PH.reps1.map((rep, i) => {
                    const birth = PH.bars1[0][i];
                    const death = PH.bars1[1][i];
                    return {
                        'dgraph.type': "Rep1", 
                        birth: birth,
                        death: death,
                        persistence: death - birth,
                        simplices: rep.map((simplex, _) => {
                            return {
                                'dgraph.type': "Simplex1",
                                'v1': cas[simplex[0]-1],
                                'v2': cas[simplex[1]-1],
                            }
                        }),
                    };
                });
        
                const reps2 = PH.reps2.map((rep, i) => {
                    const birth = PH.bars2[0][i];
                    const death = PH.bars2[1][i];
                    return {
                        'dgraph.type': "Rep2", 
                        birth: birth,
                        death: death,
                        persistence: death - birth,
                        simplices: rep.map((simplex, _) => {
                            return {
                                'dgraph.type': "Simplex2",
                                'v1': cas[simplex[0]-1],
                                'v2': cas[simplex[1]-1],
                                'v3': cas[simplex[2]-1],
                            }
                        }),
                    };
                });
        
                const prot = {
                    'dgraph.type': "AFProt",
                    acc: "A0A3S0EAG4",
                    n: PH.n,
                    cas: cas,
                    reps1: reps1,
                    reps2: reps2,
                };
                createData(dgraphClient, prot);
            });
        });
    }

    const after = Date.now();
    console.log(after - before)
}

main()
    .then(() => {
        console.log("\nDONE!");
    })
    .catch((e) => {
        console.log("ERROR: ", e);
    });
