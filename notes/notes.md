neo4j.
[x] set home env var.
[x] set auto username and password.
[x] see if you can connect locally to it?? Yes, works perfectly.
[x] import a json with cypher queries.
[x] time importing ~9k jsons.

convert json.gz to 1 bson.gz per proteome
[x] see if it makes an improvement in size and read speed using julia code.
    It didn't improve anything.
[ ] use rust db/dgraph/src/bin/bulk.rs for inspo to do the operation fast.

I was writing json2bson scripts and realize that it is fastest right now.
It is slower to collect 1000 PH jsons and read that. It even takes up more space as BSON??

Arrow forces it to be a table (all x coords is in ArrowTable.x for all 
proteins) but reads super fast with lz4 compression. 0.16 sec for 1000 files vs. 2.3 sec for json.gz.

Comparison of disk usages for DBs:
https://www.arangodb.com/2012/07/collection-disk-usage-arangodb/



