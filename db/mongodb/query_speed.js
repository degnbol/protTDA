#!/usr/bin/env -S mongosh --quiet
use("protTDA")
nTotal = db.AF.countDocuments()
before = Date.now()
query = db.AF.find({pers1: {$elemMatch: {$gt: 5}}}, {_id: 1})
after = Date.now()
print(query.count(), "/", nTotal, "(", after - before, ")")
