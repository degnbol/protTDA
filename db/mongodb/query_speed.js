#!/usr/bin/env -S mongosh --quiet
use("protTDA")

lastN = 0
for (let i = 0; i < 10000; i++) {
    while (true) {
        N = db.AF.countDocuments()
        if (N > lastN) {
            lastN = N
            break
        }
        else { sleep(10000) }
    }
    before = Date.now()
    query = db.AF.find({pers1: {$elemMatch: {$gt: 8}}}, {_id: 1})
    after = Date.now()
    print(query.count(), "/", N, "duration:", after - before, "time:", after)
    print(db.runCommand({dbStats: 1}))
    sleep(10000)
}
