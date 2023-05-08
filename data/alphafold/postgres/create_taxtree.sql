CREATE TABLE taxtree (
    tax    INTEGER     NOT NULL,
    parent INTEGER     NOT NULL,
    rankp  VARCHAR(7)  NOT NULL,
    rank   VARCHAR(15) NOT NULL,
    domain CHAR        NOT NULL
);
