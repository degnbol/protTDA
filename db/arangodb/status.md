15 TB estimated final size which is less than half of mongoDB. However queries 
seem to be running quite slow.

They are probably just as slow with mongo since I messed up the js timing and 
was measuring defining the query and not actually running it.
The key to getting good query performance will be indexing. On arango it turns 
out, there is no support for indexing on array elements yet. This means we 
would have to use a graph approach which I tried but it takes a long time to 
load and seems excessive. The data is naturally document style, since we barely 
have any connection between each protein. Even the connection to PDB structures 
could be considered another field for the protein entry.

Mongo does have indexing on array entries and even on any kind of complicated 
nested structure (https://www.mongodb.com/docs/manual/core/index-multikey/) and 
it is the number one for document store on 
https://db-engines.com/en/system/MongoDB

