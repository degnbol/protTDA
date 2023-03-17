#!/usr/bin/env -S arangosh --server.password "" --javascript.execute
const internal = require("internal");
const fs = require("fs");
const gm = require("@arangodb/general-graph");
db._createDatabase("protTDA");
db._useDatabase("protTDA");


edgeDef = gm._edgeDefinitions(
    gm._relation("hasCa", "AFProt", "Ca"),
    gm._relation("hasRep1", "AFProt", "Rep1"),
    gm._relation("hasRep2", "AFProt", "Rep2"),
    gm._relation("hasSimplex1", "Rep1", "Simplex1"),
    gm._relation("hasSimplex2", "Rep2", "Simplex2"),
    gm._relation("hasCa1", "Simplex1", "Ca"),
    gm._relation("hasCa2", "Simplex2", "Ca"),
)

// reset
gm._drop("AF", true);
// vertex collections mentioned in the edge definitions are also created
AF = gm._create("AF", edgeDef);
// if it was already created
AF = gm._graph("AF");

// https://www.arangodb.com/docs/stable/indexing-index-basics.html
// https://www.arangodb.com/docs/stable/indexing-which-index.html
// run these before loading everything and see the read speed affected to understand how heavy each index is to calc.
// single field calls separately, it makes a huge difference.
AF.AFProt.ensureIndex({ type: "persistent", fields: ["n"], fieldValueTypes: 'integer', unique: false, inBackground: true });
AF.Rep1.ensureIndex({ type: "persistent", fields: ["persistence"], fieldValueTypes: 'double', unique: false, inBackground: true });
AF.Rep2.ensureIndex({ type: "persistent", fields: ["persistence"], fieldValueTypes: 'double', unique: false, inBackground: true });
// search in range
AF.Rep1.ensureIndex({ type: "zkd", fields: ["birth", "death"], fieldValueTypes: 'double', unique: false, inBackground: true });
AF.Rep1.ensureIndex({ type: "zkd", fields: ["x", "y", "z"], fieldValueTypes: 'double', unique: false, inBackground: true });
AF.Ca.ensureIndex({ type: "persistent", fields: ["cent1"], fieldValueTypes: 'double', unique: false, inBackground: true });
AF.Ca.ensureIndex({ type: "persistent", fields: ["cent2"], fieldValueTypes: 'double', unique: false, inBackground: true });

