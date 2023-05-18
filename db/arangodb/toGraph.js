#!/usr/bin/env -S arangosh --server.password "" --javascript.execute
const fs = require("fs")

db._query(fs.read("toGraph.aql")).toArray().length

