CREATE TABLE TAX (
    acc       VARCHAR PRIMARY KEY,
    accv      VARCHAR UNIQUE NOT NULL,
    tax       INTEGER NOT NULL,
    gi        BIGINT NOT NULL
);

COPY TAX(acc,accv,tax,gi)
FROM '../prot.accession2taxid'
DELIMITER E'\t'
CSV HEADER;
