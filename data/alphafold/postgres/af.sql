CREATE TABLE AF (
    acc       VARCHAR(10) PRIMARY KEY,
    taxon     INTEGER NOT NULL,
    n         INTEGER NOT NULL,
    maxRep1   INTEGER NOT NULL,
    maxRep2   INTEGER NOT NULL,
    maxPers1  REAL    NOT NULL,
    maxPers2  REAL    NOT NULL,
    meanPLDDT REAL    NOT NULL,
    nRep1     INTEGER NOT NULL,
    nRep1_t1  INTEGER NOT NULL,
    nRep1_t2  INTEGER NOT NULL,
    nRep1_t3  INTEGER NOT NULL,
    nRep1_t4  INTEGER NOT NULL,
    nRep1_t5  INTEGER NOT NULL,
    nRep1_t6  INTEGER NOT NULL,
    nRep1_t7  INTEGER NOT NULL,
    nRep1_t8  INTEGER NOT NULL,
    nRep1_t9  INTEGER NOT NULL,
    nRep1_t10 INTEGER NOT NULL,
    nRep2     INTEGER NOT NULL,
    nRep2_t01 INTEGER NOT NULL,
    nRep2_t02 INTEGER NOT NULL,
    nRep2_t03 INTEGER NOT NULL,
    nRep2_t04 INTEGER NOT NULL,
    nRep2_t05 INTEGER NOT NULL,
    nRep2_t06 INTEGER NOT NULL,
    nRep2_t07 INTEGER NOT NULL,
    nRep2_t08 INTEGER NOT NULL,
    nRep2_t09 INTEGER NOT NULL,
    nRep2_t1  INTEGER NOT NULL
);

-- was done after reading data
create index idx_n         on af(n);
create index idx_taxon     on af(taxon);
create index idx_meanplddt on af(meanplddt);
create index idx_maxpers1  on af(maxpers1);
create index idx_maxpers2  on af(maxpers2);
create index idx_nrep1     on af(nrep1);
create index idx_nrep2     on af(nrep2);
create index idx_nrep1_t1  on af(nrep1_t1);
create index idx_nrep2_t1  on af(nrep2_t1);
