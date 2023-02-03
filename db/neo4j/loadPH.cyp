// speed-up and sanity.
CREATE CONSTRAINT FOR (o:Proteome) REQUIRE o.id IS UNIQUE;
CREATE CONSTRAINT FOR (a:Accession) REQUIRE a.accession IS UNIQUE;

// clear
match (n) detach delete n;

WITH "PH/100/100-0" AS dir
// create if not already there or just match it
MERGE (o:Proteome{id: split(dir, '/')[-1]})
WITH dir, o
CALL apoc.load.directory("*.json.gz", "file:" + dir, {recursive: false})
YIELD value AS fname
WITH o, collect(fname)[0..100] AS fnames
UNWIND fnames AS fname
// load file
CALL apoc.load.json("file:" + fname)
YIELD value AS struct
CREATE (a:Accession{accession: split(split(fname, '/')[-1], '-')[1], n: struct.n})
MERGE (o)-[:HAS]->(a)
WITH a, struct
// Subqueries
// https://neo4j.com/docs/cypher-manual/current/clauses/call-subquery/
// Add vertices with xyz predited by alphafold
CALL {
    WITH a, struct
    UNWIND range(0, size(struct.x)-1) AS i
    // merge would be slow to check for this long list of properties.
    CREATE (a)-[:HAS]->(p:AF {
        x: struct.x[i],
        y: struct.y[i],
        z: struct.z[i],
        cent1: struct.cent1[i],
        cent2: struct.cent2[i]
    })
    // a returning subquery.
    // This means p outside will be a table of rows each with one node in order 
    // as they were added.
    RETURN p
}
// collect transforms the table with a node on each row to a list so we can 
// pick a node with indexing.
WITH a, struct, collect(p) AS pc
// Add dim 1 reps and bars
CALL {
    WITH a, struct, pc
    UNWIND range(0, size(struct.bars1[0])-1) AS i
    WITH a, struct, i, pc
    CREATE (a)-[:HAS]->(r:Rep1{birth: struct.bars1[0][i], death: struct.bars1[1][i]})
    WITH r, struct.reps1[i] as rep, pc
    UNWIND range(0, size(rep)-1) AS simplex
    UNWIND rep[simplex] AS n // two ns
    WITH simplex, r, pc[n-1] AS p // zero-indexing in cypher
    CREATE (r)-[:IN_REP{simplex: simplex}]->(p)
}
// Add dim 2 reps and bars
CALL {
    WITH a, struct, pc
    UNWIND range(0, size(struct.bars2[0])-1) AS i
    WITH a, struct, i, pc
    CREATE (a)-[:HAS]->(r:Rep2{birth: struct.bars2[0][i], death: struct.bars2[1][i]})
    WITH pc, r, struct.reps2[i] AS rep
    UNWIND range(0, size(rep)-1) AS simplex
    UNWIND rep[simplex] AS n // three ns
    WITH simplex, r, pc[n-1] AS p // zero-indexing in cypher
    CREATE (r)-[:IN_REP{simplex: simplex}]->(p)
}
;

