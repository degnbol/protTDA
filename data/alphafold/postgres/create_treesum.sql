CREATE TABLE genus as
SELECT
    false as by_protein,
    taxtree.parent, taxtree.domain,
    SUM(proteins)                  as proteins,
    AVG(avg_n)                    as avg_n,
    AVG(avg_maxrep1)              as avg_maxrep1,
    AVG(avg_maxrep2)              as avg_maxrep2,
    AVG(avg_maxpers1)             as avg_maxpers1,
    AVG(avg_maxpers2)             as avg_maxpers2,
    AVG(avg_nrep1)                as avg_nrep1,
    AVG(avg_nrep2)                as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)             as avg_nrep1_b0,
    AVG(avg_nrep1_b1)             as avg_nrep1_b1,
    AVG(avg_nrep1_b2)             as avg_nrep1_b2,
    AVG(avg_nrep1_b3)             as avg_nrep1_b3,
    AVG(avg_nrep1_b4)             as avg_nrep1_b4,
    AVG(avg_nrep1_b5)             as avg_nrep1_b5,
    AVG(avg_nrep1_b6)             as avg_nrep1_b6,
    AVG(avg_nrep1_b7)             as avg_nrep1_b7,
    AVG(avg_nrep1_b8)             as avg_nrep1_b8,
    AVG(avg_nrep1_b9)             as avg_nrep1_b9,
    AVG(avg_nrep1_t10)            as avg_nrep1_t10,
    AVG(avg_nrep2_b00)            as avg_nrep2_b00,
    AVG(avg_nrep2_b01)            as avg_nrep2_b01,
    AVG(avg_nrep2_b02)            as avg_nrep2_b02,
    AVG(avg_nrep2_b03)            as avg_nrep2_b03,
    AVG(avg_nrep2_b04)            as avg_nrep2_b04,
    AVG(avg_nrep2_b05)            as avg_nrep2_b05,
    AVG(avg_nrep2_b06)            as avg_nrep2_b06,
    AVG(avg_nrep2_b07)            as avg_nrep2_b07,
    AVG(avg_nrep2_b08)            as avg_nrep2_b08,
    AVG(avg_nrep2_b09)            as avg_nrep2_b09,
    AVG(avg_nrep2_t1)             as avg_nrep2_t1
FROM taxtree INNER JOIN species
ON taxtree.tax = species.parent
WHERE taxtree.rankp = 'genus'
GROUP BY taxtree.parent, taxtree.domain
UNION ALL
SELECT
# TODO: make weighted
    true as by_protein,
    taxtree.parent, taxtree.domain,
    SUM(proteins)                  as proteins,
    AVG(avg_n)                    as avg_n,
    AVG(avg_maxrep1)              as avg_maxrep1,
    AVG(avg_maxrep2)              as avg_maxrep2,
    AVG(avg_maxpers1)             as avg_maxpers1,
    AVG(avg_maxpers2)             as avg_maxpers2,
    AVG(avg_nrep1)                as avg_nrep1,
    AVG(avg_nrep2)                as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)             as avg_nrep1_b0,
    AVG(avg_nrep1_b1)             as avg_nrep1_b1,
    AVG(avg_nrep1_b2)             as avg_nrep1_b2,
    AVG(avg_nrep1_b3)             as avg_nrep1_b3,
    AVG(avg_nrep1_b4)             as avg_nrep1_b4,
    AVG(avg_nrep1_b5)             as avg_nrep1_b5,
    AVG(avg_nrep1_b6)             as avg_nrep1_b6,
    AVG(avg_nrep1_b7)             as avg_nrep1_b7,
    AVG(avg_nrep1_b8)             as avg_nrep1_b8,
    AVG(avg_nrep1_b9)             as avg_nrep1_b9,
    AVG(avg_nrep1_t10)            as avg_nrep1_t10,
    AVG(avg_nrep2_b00)            as avg_nrep2_b00,
    AVG(avg_nrep2_b01)            as avg_nrep2_b01,
    AVG(avg_nrep2_b02)            as avg_nrep2_b02,
    AVG(avg_nrep2_b03)            as avg_nrep2_b03,
    AVG(avg_nrep2_b04)            as avg_nrep2_b04,
    AVG(avg_nrep2_b05)            as avg_nrep2_b05,
    AVG(avg_nrep2_b06)            as avg_nrep2_b06,
    AVG(avg_nrep2_b07)            as avg_nrep2_b07,
    AVG(avg_nrep2_b08)            as avg_nrep2_b08,
    AVG(avg_nrep2_b09)            as avg_nrep2_b09,
    AVG(avg_nrep2_t1)             as avg_nrep2_t1
FROM taxtree INNER JOIN species
ON taxtree.tax = species.parent
WHERE taxtree.rankp = 'genus'
GROUP BY taxtree.parent, taxtree.domain;

CREATE TABLE family as
SELECT
    taxtree.parent, taxtree.domain,
    SUM(proteins)           as proteins,
    AVG(avg_n)             as avg_n,
    AVG(avg_maxrep1)       as avg_maxrep1,
    AVG(avg_maxrep2)       as avg_maxrep2,
    AVG(avg_maxpers1)      as avg_maxpers1,
    AVG(avg_maxpers2)      as avg_maxpers2,
    AVG(avg_nrep1)         as avg_nrep1,
    AVG(avg_nrep2)         as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)      as avg_nrep1_b0,
    AVG(avg_nrep1_b1)      as avg_nrep1_b1,
    AVG(avg_nrep1_b2)      as avg_nrep1_b2,
    AVG(avg_nrep1_b3)      as avg_nrep1_b3,
    AVG(avg_nrep1_b4)      as avg_nrep1_b4,
    AVG(avg_nrep1_b5)      as avg_nrep1_b5,
    AVG(avg_nrep1_b6)      as avg_nrep1_b6,
    AVG(avg_nrep1_b7)      as avg_nrep1_b7,
    AVG(avg_nrep1_b8)      as avg_nrep1_b8,
    AVG(avg_nrep1_b9)      as avg_nrep1_b9,
    AVG(avg_nrep1_t10)     as avg_nrep1_t10,
    AVG(avg_nrep2_b00)     as avg_nrep2_b00,
    AVG(avg_nrep2_b01)     as avg_nrep2_b01,
    AVG(avg_nrep2_b02)     as avg_nrep2_b02,
    AVG(avg_nrep2_b03)     as avg_nrep2_b03,
    AVG(avg_nrep2_b04)     as avg_nrep2_b04,
    AVG(avg_nrep2_b05)     as avg_nrep2_b05,
    AVG(avg_nrep2_b06)     as avg_nrep2_b06,
    AVG(avg_nrep2_b07)     as avg_nrep2_b07,
    AVG(avg_nrep2_b08)     as avg_nrep2_b08,
    AVG(avg_nrep2_b09)     as avg_nrep2_b09,
    AVG(avg_nrep2_t1)      as avg_nrep2_t1
FROM taxtree INNER JOIN genus
ON taxtree.tax = genus.parent
WHERE taxtree.rankp = 'family'
GROUP BY taxtree.parent, taxtree.domain;

CREATE TABLE "order" as
SELECT
    taxtree.parent, taxtree.domain,
    SUM(proteins)           as proteins,
    AVG(avg_n)             as avg_n,
    AVG(avg_maxrep1)       as avg_maxrep1,
    AVG(avg_maxrep2)       as avg_maxrep2,
    AVG(avg_maxpers1)      as avg_maxpers1,
    AVG(avg_maxpers2)      as avg_maxpers2,
    AVG(avg_nrep1)         as avg_nrep1,
    AVG(avg_nrep2)         as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)      as avg_nrep1_b0,
    AVG(avg_nrep1_b1)      as avg_nrep1_b1,
    AVG(avg_nrep1_b2)      as avg_nrep1_b2,
    AVG(avg_nrep1_b3)      as avg_nrep1_b3,
    AVG(avg_nrep1_b4)      as avg_nrep1_b4,
    AVG(avg_nrep1_b5)      as avg_nrep1_b5,
    AVG(avg_nrep1_b6)      as avg_nrep1_b6,
    AVG(avg_nrep1_b7)      as avg_nrep1_b7,
    AVG(avg_nrep1_b8)      as avg_nrep1_b8,
    AVG(avg_nrep1_b9)      as avg_nrep1_b9,
    AVG(avg_nrep1_t10)     as avg_nrep1_t10,
    AVG(avg_nrep2_b00)     as avg_nrep2_b00,
    AVG(avg_nrep2_b01)     as avg_nrep2_b01,
    AVG(avg_nrep2_b02)     as avg_nrep2_b02,
    AVG(avg_nrep2_b03)     as avg_nrep2_b03,
    AVG(avg_nrep2_b04)     as avg_nrep2_b04,
    AVG(avg_nrep2_b05)     as avg_nrep2_b05,
    AVG(avg_nrep2_b06)     as avg_nrep2_b06,
    AVG(avg_nrep2_b07)     as avg_nrep2_b07,
    AVG(avg_nrep2_b08)     as avg_nrep2_b08,
    AVG(avg_nrep2_b09)     as avg_nrep2_b09,
    AVG(avg_nrep2_t1)      as avg_nrep2_t1
FROM taxtree INNER JOIN family
ON taxtree.tax = family.parent
WHERE taxtree.rankp = 'order'
GROUP BY taxtree.parent, taxtree.domain;

CREATE TABLE class as
SELECT
    taxtree.parent, taxtree.domain,
    SUM(proteins)           as proteins,
    AVG(avg_n)             as avg_n,
    AVG(avg_maxrep1)       as avg_maxrep1,
    AVG(avg_maxrep2)       as avg_maxrep2,
    AVG(avg_maxpers1)      as avg_maxpers1,
    AVG(avg_maxpers2)      as avg_maxpers2,
    AVG(avg_nrep1)         as avg_nrep1,
    AVG(avg_nrep2)         as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)      as avg_nrep1_b0,
    AVG(avg_nrep1_b1)      as avg_nrep1_b1,
    AVG(avg_nrep1_b2)      as avg_nrep1_b2,
    AVG(avg_nrep1_b3)      as avg_nrep1_b3,
    AVG(avg_nrep1_b4)      as avg_nrep1_b4,
    AVG(avg_nrep1_b5)      as avg_nrep1_b5,
    AVG(avg_nrep1_b6)      as avg_nrep1_b6,
    AVG(avg_nrep1_b7)      as avg_nrep1_b7,
    AVG(avg_nrep1_b8)      as avg_nrep1_b8,
    AVG(avg_nrep1_b9)      as avg_nrep1_b9,
    AVG(avg_nrep1_t10)     as avg_nrep1_t10,
    AVG(avg_nrep2_b00)     as avg_nrep2_b00,
    AVG(avg_nrep2_b01)     as avg_nrep2_b01,
    AVG(avg_nrep2_b02)     as avg_nrep2_b02,
    AVG(avg_nrep2_b03)     as avg_nrep2_b03,
    AVG(avg_nrep2_b04)     as avg_nrep2_b04,
    AVG(avg_nrep2_b05)     as avg_nrep2_b05,
    AVG(avg_nrep2_b06)     as avg_nrep2_b06,
    AVG(avg_nrep2_b07)     as avg_nrep2_b07,
    AVG(avg_nrep2_b08)     as avg_nrep2_b08,
    AVG(avg_nrep2_b09)     as avg_nrep2_b09,
    AVG(avg_nrep2_t1)      as avg_nrep2_t1
FROM taxtree INNER JOIN "order"
ON taxtree.tax = "order".parent
WHERE taxtree.rankp = 'class'
GROUP BY taxtree.parent, taxtree.domain;

CREATE TABLE phylum as
SELECT
    taxtree.parent, taxtree.domain,
    SUM(proteins)           as proteins,
    AVG(avg_n)             as avg_n,
    AVG(avg_maxrep1)       as avg_maxrep1,
    AVG(avg_maxrep2)       as avg_maxrep2,
    AVG(avg_maxpers1)      as avg_maxpers1,
    AVG(avg_maxpers2)      as avg_maxpers2,
    AVG(avg_nrep1)         as avg_nrep1,
    AVG(avg_nrep2)         as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)      as avg_nrep1_b0,
    AVG(avg_nrep1_b1)      as avg_nrep1_b1,
    AVG(avg_nrep1_b2)      as avg_nrep1_b2,
    AVG(avg_nrep1_b3)      as avg_nrep1_b3,
    AVG(avg_nrep1_b4)      as avg_nrep1_b4,
    AVG(avg_nrep1_b5)      as avg_nrep1_b5,
    AVG(avg_nrep1_b6)      as avg_nrep1_b6,
    AVG(avg_nrep1_b7)      as avg_nrep1_b7,
    AVG(avg_nrep1_b8)      as avg_nrep1_b8,
    AVG(avg_nrep1_b9)      as avg_nrep1_b9,
    AVG(avg_nrep1_t10)     as avg_nrep1_t10,
    AVG(avg_nrep2_b00)     as avg_nrep2_b00,
    AVG(avg_nrep2_b01)     as avg_nrep2_b01,
    AVG(avg_nrep2_b02)     as avg_nrep2_b02,
    AVG(avg_nrep2_b03)     as avg_nrep2_b03,
    AVG(avg_nrep2_b04)     as avg_nrep2_b04,
    AVG(avg_nrep2_b05)     as avg_nrep2_b05,
    AVG(avg_nrep2_b06)     as avg_nrep2_b06,
    AVG(avg_nrep2_b07)     as avg_nrep2_b07,
    AVG(avg_nrep2_b08)     as avg_nrep2_b08,
    AVG(avg_nrep2_b09)     as avg_nrep2_b09,
    AVG(avg_nrep2_t1)      as avg_nrep2_t1
FROM taxtree INNER JOIN class
ON taxtree.tax = class.parent
WHERE taxtree.rankp = 'phylum'
GROUP BY taxtree.parent, taxtree.domain;

CREATE TABLE kingdom as
SELECT
    taxtree.parent, taxtree.domain,
    SUM(proteins)           as proteins,
    AVG(avg_n)             as avg_n,
    AVG(avg_maxrep1)       as avg_maxrep1,
    AVG(avg_maxrep2)       as avg_maxrep2,
    AVG(avg_maxpers1)      as avg_maxpers1,
    AVG(avg_maxpers2)      as avg_maxpers2,
    AVG(avg_nrep1)         as avg_nrep1,
    AVG(avg_nrep2)         as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)      as avg_nrep1_b0,
    AVG(avg_nrep1_b1)      as avg_nrep1_b1,
    AVG(avg_nrep1_b2)      as avg_nrep1_b2,
    AVG(avg_nrep1_b3)      as avg_nrep1_b3,
    AVG(avg_nrep1_b4)      as avg_nrep1_b4,
    AVG(avg_nrep1_b5)      as avg_nrep1_b5,
    AVG(avg_nrep1_b6)      as avg_nrep1_b6,
    AVG(avg_nrep1_b7)      as avg_nrep1_b7,
    AVG(avg_nrep1_b8)      as avg_nrep1_b8,
    AVG(avg_nrep1_b9)      as avg_nrep1_b9,
    AVG(avg_nrep1_t10)     as avg_nrep1_t10,
    AVG(avg_nrep2_b00)     as avg_nrep2_b00,
    AVG(avg_nrep2_b01)     as avg_nrep2_b01,
    AVG(avg_nrep2_b02)     as avg_nrep2_b02,
    AVG(avg_nrep2_b03)     as avg_nrep2_b03,
    AVG(avg_nrep2_b04)     as avg_nrep2_b04,
    AVG(avg_nrep2_b05)     as avg_nrep2_b05,
    AVG(avg_nrep2_b06)     as avg_nrep2_b06,
    AVG(avg_nrep2_b07)     as avg_nrep2_b07,
    AVG(avg_nrep2_b08)     as avg_nrep2_b08,
    AVG(avg_nrep2_b09)     as avg_nrep2_b09,
    AVG(avg_nrep2_t1)      as avg_nrep2_t1
FROM taxtree INNER JOIN phylum
ON taxtree.tax = phylum.parent
WHERE taxtree.rankp = 'kingdom'
GROUP BY taxtree.parent, taxtree.domain;

create table toplevel as
select taxtree.domain, taxtree.rankp, taxtree.parent from taxtree
except
select taxtree.domain, taxtree.rank, taxtree.tax from taxtree;

CREATE TABLE treesum AS
    SELECT kingdom.*, 'kingdom' AS rankp FROM kingdom
    UNION ALL
    SELECT phylum.*, 'phylum' AS rankp FROM phylum
    UNION ALL
    SELECT class.*, 'class' AS rankp FROM class
    UNION ALL
    SELECT "order".*, 'order' AS rankp FROM "order"
    UNION ALL
    SELECT family.*, 'family' AS rankp FROM family
    UNION ALL
    SELECT genus.*, 'genus' AS rankp FROM genus
    UNION ALL
    SELECT species.*, 'species' AS rankp FROM species;
ALTER TABLE treesum RENAME COLUMN parent TO tax;
ALTER TABLE treesum RENAME COLUMN rankp TO rank;

CREATE TABLE domain as
SELECT
    false                     as by_protein,
    toplevel.domain,
    SUM(proteins)           as proteins,
    AVG(avg_n)             as avg_n,
    AVG(avg_maxrep1)       as avg_maxrep1,
    AVG(avg_maxrep2)       as avg_maxrep2,
    AVG(avg_maxpers1)      as avg_maxpers1,
    AVG(avg_maxpers2)      as avg_maxpers2,
    AVG(avg_nrep1)         as avg_nrep1,
    AVG(avg_nrep2)         as avg_nrep2,
    COALESCE(AVG(var_n)       ,0) as var_n,
    COALESCE(AVG(var_maxrep1) ,0) as var_maxrep1,
    COALESCE(AVG(var_maxrep2) ,0) as var_maxrep2,
    COALESCE(AVG(var_maxpers1),0) as var_maxpers1,
    COALESCE(AVG(var_maxpers2),0) as var_maxpers2,
    COALESCE(AVG(var_nrep1)   ,0) as var_nrep1,
    COALESCE(AVG(var_nrep2)   ,0) as var_nrep2,
    AVG(avg_nrep1_b0)      as avg_nrep1_b0,
    AVG(avg_nrep1_b1)      as avg_nrep1_b1,
    AVG(avg_nrep1_b2)      as avg_nrep1_b2,
    AVG(avg_nrep1_b3)      as avg_nrep1_b3,
    AVG(avg_nrep1_b4)      as avg_nrep1_b4,
    AVG(avg_nrep1_b5)      as avg_nrep1_b5,
    AVG(avg_nrep1_b6)      as avg_nrep1_b6,
    AVG(avg_nrep1_b7)      as avg_nrep1_b7,
    AVG(avg_nrep1_b8)      as avg_nrep1_b8,
    AVG(avg_nrep1_b9)      as avg_nrep1_b9,
    AVG(avg_nrep1_t10)     as avg_nrep1_t10,
    AVG(avg_nrep2_b00)     as avg_nrep2_b00,
    AVG(avg_nrep2_b01)     as avg_nrep2_b01,
    AVG(avg_nrep2_b02)     as avg_nrep2_b02,
    AVG(avg_nrep2_b03)     as avg_nrep2_b03,
    AVG(avg_nrep2_b04)     as avg_nrep2_b04,
    AVG(avg_nrep2_b05)     as avg_nrep2_b05,
    AVG(avg_nrep2_b06)     as avg_nrep2_b06,
    AVG(avg_nrep2_b07)     as avg_nrep2_b07,
    AVG(avg_nrep2_b08)     as avg_nrep2_b08,
    AVG(avg_nrep2_b09)     as avg_nrep2_b09,
    AVG(avg_nrep2_t1)      as avg_nrep2_t1
FROM toplevel INNER JOIN treesum
ON toplevel.parent = treesum.tax
GROUP BY toplevel.domain
UNION ALL
SELECT
    true                     as by_protein,
    domain,
    SUM(proteins)           as proteins,
    SUM(avg_n*proteins)/SUM(proteins) as avg_n,
    SUM(avg_maxrep1*proteins)/SUM(proteins)       as avg_maxrep1,
    SUM(avg_maxrep2*proteins)/SUM(proteins)       as avg_maxrep2,
    SUM(avg_maxpers1*proteins)/SUM(proteins)      as avg_maxpers1,
    SUM(avg_maxpers2*proteins)/SUM(proteins)      as avg_maxpers2,
    SUM(avg_nrep1*proteins)/SUM(proteins)         as avg_nrep1,
    SUM(avg_nrep2*proteins)/SUM(proteins)         as avg_nrep2,
    COALESCE(SUM(var_n*proteins)/SUM(proteins)       ,0) as var_n,
    COALESCE(SUM(var_maxrep1*proteins)/SUM(proteins) ,0) as var_maxrep1,
    COALESCE(SUM(var_maxrep2*proteins)/SUM(proteins) ,0) as var_maxrep2,
    COALESCE(SUM(var_maxpers1*proteins)/SUM(proteins),0) as var_maxpers1,
    COALESCE(SUM(var_maxpers2*proteins)/SUM(proteins),0) as var_maxpers2,
    COALESCE(SUM(var_nrep1*proteins)/SUM(proteins)   ,0) as var_nrep1,
    COALESCE(SUM(var_nrep2*proteins)/SUM(proteins)   ,0) as var_nrep2,
    SUM(avg_nrep1_b0*proteins)/SUM(proteins)      as avg_nrep1_b0,
    SUM(avg_nrep1_b1*proteins)/SUM(proteins)      as avg_nrep1_b1,
    SUM(avg_nrep1_b2*proteins)/SUM(proteins)      as avg_nrep1_b2,
    SUM(avg_nrep1_b3*proteins)/SUM(proteins)      as avg_nrep1_b3,
    SUM(avg_nrep1_b4*proteins)/SUM(proteins)      as avg_nrep1_b4,
    SUM(avg_nrep1_b5*proteins)/SUM(proteins)      as avg_nrep1_b5,
    SUM(avg_nrep1_b6*proteins)/SUM(proteins)      as avg_nrep1_b6,
    SUM(avg_nrep1_b7*proteins)/SUM(proteins)      as avg_nrep1_b7,
    SUM(avg_nrep1_b8*proteins)/SUM(proteins)      as avg_nrep1_b8,
    SUM(avg_nrep1_b9*proteins)/SUM(proteins)      as avg_nrep1_b9,
    SUM(avg_nrep1_t10*proteins)/SUM(proteins)     as avg_nrep1_t10,
    SUM(avg_nrep2_b00*proteins)/SUM(proteins)     as avg_nrep2_b00,
    SUM(avg_nrep2_b01*proteins)/SUM(proteins)     as avg_nrep2_b01,
    SUM(avg_nrep2_b02*proteins)/SUM(proteins)     as avg_nrep2_b02,
    SUM(avg_nrep2_b03*proteins)/SUM(proteins)     as avg_nrep2_b03,
    SUM(avg_nrep2_b04*proteins)/SUM(proteins)     as avg_nrep2_b04,
    SUM(avg_nrep2_b05*proteins)/SUM(proteins)     as avg_nrep2_b05,
    SUM(avg_nrep2_b06*proteins)/SUM(proteins)     as avg_nrep2_b06,
    SUM(avg_nrep2_b07*proteins)/SUM(proteins)     as avg_nrep2_b07,
    SUM(avg_nrep2_b08*proteins)/SUM(proteins)     as avg_nrep2_b08,
    SUM(avg_nrep2_b09*proteins)/SUM(proteins)     as avg_nrep2_b09,
    SUM(avg_nrep2_t1*proteins)/SUM(proteins)      as avg_nrep2_t1
from species
GROUP BY domain;





