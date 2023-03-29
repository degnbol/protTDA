#!/usr/bin/env -S arangosh --server.password "" --javascript.execute
// USE: ./import.js ../../data/alphafold/PH/100
internal = require("internal");
fs = require("fs");
db._useDatabase("protTDA");
// reset
// db._drop('AF')
db._create('AF')

// d0 = "../../data/alphafold/PH/100";
// d1 = "../../data/alphafold/PH/100/100-0";
d0 = ARGUMENTS[0];
d1s = fs.list(d0);
for (let i=0; i < d1s.length; i++) {
    d1 = fs.join(d0, d1s[i]);
    print(d1)
    fnames = fs.list(d1);
    for (let ii=0; ii < fnames.length; ii++) {
        if (ii % 100 == 0) {print(ii, '/', fnames.length)}
        fname = fnames[ii];
        if (fname.startsWith("AF")) {
            PH = JSON.parse(fs.readGzip(fs.join(d1, fname)));
            PH["_key"] = fname.split('-')[1]; // accession
            db.AF.save(PH);
        }
    }
}


