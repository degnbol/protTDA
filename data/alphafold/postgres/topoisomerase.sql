
create table topo (
    acc TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    proteins TEXT,
    genes TEXT,
    organism TEXT NOT NULL,
    length INTEGER NOT NULL,
    PDB TEXT,
    sequence TEXT NOT NULL,
    EC TEXT,
    taxes TEXT NOT NULL
);

\copy topo from '../topoisomerase/topos.tsv' DELIMITER E'\t' CSV HEADER;

create table topoaf as
select * from topo inner join af using(acc);

\copy topoaf to '../topoisomerase/topos-AF.tsv' DELIMITER E'\t' CSV HEADER;

