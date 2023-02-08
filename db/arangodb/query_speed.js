#!/usr/bin/env -S arangosh --server.password "" --javascript.execute
internal = require("internal");
fs = require("fs"); // file system stuff
const sleep = internal.sleep
db._useDatabase("protTDA");

lastN = 0

for (let i = 0; i < 10000; i++) {
    while (true) {
        N = db.AF.count()
        if (N > lastN) {
            lastN = N
            break
        }
        else { sleep(10) }
    }
    before = Date.now()
    nPersist = db._query(`
        FOR prot IN AF
        FILTER prot.pers1 ANY > 8
        RETURN { acc: prot._key }
        `).toArray().length;
    after = Date.now()
    figs = db.AF.figures()
    print(nPersist, "/", N, "duration:", after - before, "time:", after, "documentsSize:", figs["documentsSize"], "indexesSize:", figs["indexes"]["size"])
    sleep(10)
}

