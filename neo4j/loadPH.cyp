// load file
CALL apoc.load.json("file:PH/100/100-0/AF-A0A431QUU5-F1-model_v3.json.gz")
// has to be called value
YIELD value
MERGE (a:Accession{accession: "A0A431QUU5", n: value.n})
WITH a, value
// Subqueries
// https://neo4j.com/docs/cypher-manual/current/clauses/call-subquery/
// Add vertices with xyz predited by alphafold
CALL {
    WITH a, value
    UNWIND range(0, size(value.x)-1) AS i
    MERGE (p:AF {
        x: value.x[i],
        y: value.y[i],
        z: value.z[i],
        cent1: value.cent1[i],
        cent2: value.cent2[i]
    })
    MERGE (a)-[:HAS]->(p)
    RETURN p
}
WITH a, value, collect(p) as pc
// Add dim 1 reps and bars
CALL {
    WITH a, value, pc
    UNWIND range(0, size(value.bars1[0])-1) AS i
    WITH a, pc, value.bars1[0][i] as birth, value.bars1[1][i] as death, value.reps1[i] as rep
    WITH a, pc, birth, death, rep, death - birth as persistence
    WHERE persistence > 0.001
    MERGE (r:Rep1{birth: birth, death: death, persistence: persistence})
    MERGE (a)-[:HAS]->(r)
    WITH pc, r, rep
    UNWIND range(0, size(rep)-1) AS simplex
    UNWIND rep[simplex] AS n
    WITH simplex, r, pc[n-1] as p // zero-indexing in cypher
    MERGE (r)-[:IN_REP{simplex: simplex}]->(p)
}
// Add dim 2 reps and bars
CALL {
    WITH a, value, pc
    UNWIND range(0, size(value.bars2[0])-1) AS i
    WITH a, pc, value.bars2[0][i] as birth, value.bars2[1][i] as death, value.reps2[i] as rep
    WITH a, pc, birth, death, rep, death - birth as persistence
    WHERE persistence > 0.001
    MERGE (r:Rep2{birth: birth, death: death, persistence: persistence})
    MERGE (a)-[:HAS]->(r)
    WITH pc, r, rep
    UNWIND range(0, size(rep)-1) AS simplex
    UNWIND rep[simplex] AS n
    WITH simplex, r, pc[n-1] as p // zero-indexing in cypher
    MERGE (r)-[:IN_REP{simplex: simplex}]->(p)
}
;
