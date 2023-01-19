// speed-up and sanity.
CREATE CONSTRAINT ON (a:Accession) ASSERT a.accession IS UNIQUE;

// recursive by default
CALL apoc.load.directory("*.json.gz", "file:PH/100/100-0/")
YIELD value AS fname
// load file
CALL apoc.load.json("file:" + fname)
YIELD value AS struct
// All merge calls may be replaced with CREATE for potential speed-up at the 
// cost of potentially causing duplicate elements.
CREATE (a:Accession{accession: "A0A431QUU5", n: struct.n})
WITH a, struct
// Subqueries
// https://neo4j.com/docs/cypher-manual/current/clauses/call-subquery/
// Add vertices with xyz predited by alphafold
CALL {
    WITH a, struct
    UNWIND range(0, size(struct.x)-1) AS i
    // merge would be slow to check for this long list of properties.
    CREATE (p:AF {
        x: struct.x[i],
        y: struct.y[i],
        z: struct.z[i],
        cent1: struct.cent1[i],
        cent2: struct.cent2[i]
    })
    MERGE (a)-[:HAS]->(p)
    // a returning subquery.
    // This means p outside will be a table of rows each with one node in order 
    // as they were added.
    RETURN p
}
// collect transforms the table with a node on each row to a list so we can 
// pick a node with indexing.
WITH a, struct, collect(p) as pc
// Add dim 1 reps and bars
CALL {
    WITH a, struct, pc
    UNWIND range(0, size(struct.bars1[0])-1) AS i
    WITH a, pc, struct.bars1[0][i] as birth, struct.bars1[1][i] as death, struct.reps1[i] as rep
    WITH a, pc, birth, death, rep, death - birth as persistence
    WHERE persistence > 0.001
    CREATE (r:Rep1{birth: birth, death: death, persistence: persistence})
    MERGE (a)-[:HAS]->(r)
    WITH pc, r, rep
    UNWIND range(0, size(rep)-1) AS simplex
    UNWIND rep[simplex] AS n
    WITH simplex, r, pc[n-1] as p // zero-indexing in cypher
    MERGE (r)-[:IN_REP{simplex: simplex}]->(p)
}
// Add dim 2 reps and bars
CALL {
    WITH a, struct, pc
    UNWIND range(0, size(struct.bars2[0])-1) AS i
    WITH a, pc, struct.bars2[0][i] as birth, struct.bars2[1][i] as death, struct.reps2[i] as rep
    WITH a, pc, birth, death, rep, death - birth as persistence
    WHERE persistence > 0.001
    CREATE (r:Rep2{birth: birth, death: death, persistence: persistence})
    MERGE (a)-[:HAS]->(r)
    WITH pc, r, rep
    UNWIND range(0, size(rep)-1) AS simplex
    UNWIND rep[simplex] AS n
    WITH simplex, r, pc[n-1] as p // zero-indexing in cypher
    MERGE (r)-[:IN_REP{simplex: simplex}]->(p)
}
;

CREATE INDEX ON :Accession(accession)
