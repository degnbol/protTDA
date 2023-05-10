CREATE TABLE treenode_perprot as
SELECT
    parent as tax, rankp as rank,
    count(*)                       as proteins,
    AVG(n)                         as avg_n,
    AVG(maxrep1)                   as avg_maxrep1,
    AVG(maxrep2)                   as avg_maxrep2,
    AVG(maxpers1)                  as avg_maxpers1,
    AVG(maxpers2)                  as avg_maxpers2,
    AVG(nrep1)                     as avg_nrep1,
    AVG(nrep2)                     as avg_nrep2,
    COALESCE(VARIANCE(n)       ,0) as var_n,
    COALESCE(VARIANCE(maxrep1) ,0) as var_maxrep1,
    COALESCE(VARIANCE(maxrep2) ,0) as var_maxrep2,
    COALESCE(VARIANCE(maxpers1),0) as var_maxpers1,
    COALESCE(VARIANCE(maxpers2),0) as var_maxpers2,
    COALESCE(VARIANCE(nrep1)   ,0) as var_nrep1,
    COALESCE(VARIANCE(nrep2)   ,0) as var_nrep2,
    AVG(nrep1     - nrep1_t1)      as avg_nrep1_b0,
    AVG(nrep1_t1  - nrep1_t2)      as avg_nrep1_b1,
    AVG(nrep1_t2  - nrep1_t3)      as avg_nrep1_b2,
    AVG(nrep1_t3  - nrep1_t4)      as avg_nrep1_b3,
    AVG(nrep1_t4  - nrep1_t5)      as avg_nrep1_b4,
    AVG(nrep1_t5  - nrep1_t6)      as avg_nrep1_b5,
    AVG(nrep1_t6  - nrep1_t7)      as avg_nrep1_b6,
    AVG(nrep1_t7  - nrep1_t8)      as avg_nrep1_b7,
    AVG(nrep1_t8  - nrep1_t9)      as avg_nrep1_b8,
    AVG(nrep1_t9  - nrep1_t10)     as avg_nrep1_b9,
    AVG(nrep1_t10)                 as avg_nrep1_t10,
    AVG(nrep2     - nrep2_t01)     as avg_nrep2_b00,
    AVG(nrep2_t01 - nrep2_t02)     as avg_nrep2_b01,
    AVG(nrep2_t02 - nrep2_t03)     as avg_nrep2_b02,
    AVG(nrep2_t03 - nrep2_t04)     as avg_nrep2_b03,
    AVG(nrep2_t04 - nrep2_t05)     as avg_nrep2_b04,
    AVG(nrep2_t05 - nrep2_t06)     as avg_nrep2_b05,
    AVG(nrep2_t06 - nrep2_t07)     as avg_nrep2_b06,
    AVG(nrep2_t07 - nrep2_t08)     as avg_nrep2_b07,
    AVG(nrep2_t08 - nrep2_t09)     as avg_nrep2_b08,
    AVG(nrep2_t09 - nrep2_t1)      as avg_nrep2_b09,
    AVG(nrep2_t1)                  as avg_nrep2_t1,
    AVG(cast(nrep1     - nrep1_t1  as float)/nullif(nrep1,0)) as avg_nrep1_f0,
    AVG(cast(nrep1_t1  - nrep1_t2  as float)/nullif(nrep1,0)) as avg_nrep1_f1,
    AVG(cast(nrep1_t2  - nrep1_t3  as float)/nullif(nrep1,0)) as avg_nrep1_f2,
    AVG(cast(nrep1_t3  - nrep1_t4  as float)/nullif(nrep1,0)) as avg_nrep1_f3,
    AVG(cast(nrep1_t4  - nrep1_t5  as float)/nullif(nrep1,0)) as avg_nrep1_f4,
    AVG(cast(nrep1_t5  - nrep1_t6  as float)/nullif(nrep1,0)) as avg_nrep1_f5,
    AVG(cast(nrep1_t6  - nrep1_t7  as float)/nullif(nrep1,0)) as avg_nrep1_f6,
    AVG(cast(nrep1_t7  - nrep1_t8  as float)/nullif(nrep1,0)) as avg_nrep1_f7,
    AVG(cast(nrep1_t8  - nrep1_t9  as float)/nullif(nrep1,0)) as avg_nrep1_f8,
    AVG(cast(nrep1_t9  - nrep1_t10 as float)/nullif(nrep1,0)) as avg_nrep1_f9,
    AVG(cast(nrep1_t10             as float)/nullif(nrep1,0)) as avg_nrep1_f10,
    AVG(cast(nrep2     - nrep2_t01 as float)/nullif(nrep2,0)) as avg_nrep2_f00,
    AVG(cast(nrep2_t01 - nrep2_t02 as float)/nullif(nrep2,0)) as avg_nrep2_f01,
    AVG(cast(nrep2_t02 - nrep2_t03 as float)/nullif(nrep2,0)) as avg_nrep2_f02,
    AVG(cast(nrep2_t03 - nrep2_t04 as float)/nullif(nrep2,0)) as avg_nrep2_f03,
    AVG(cast(nrep2_t04 - nrep2_t05 as float)/nullif(nrep2,0)) as avg_nrep2_f04,
    AVG(cast(nrep2_t05 - nrep2_t06 as float)/nullif(nrep2,0)) as avg_nrep2_f05,
    AVG(cast(nrep2_t06 - nrep2_t07 as float)/nullif(nrep2,0)) as avg_nrep2_f06,
    AVG(cast(nrep2_t07 - nrep2_t08 as float)/nullif(nrep2,0)) as avg_nrep2_f07,
    AVG(cast(nrep2_t08 - nrep2_t09 as float)/nullif(nrep2,0)) as avg_nrep2_f08,
    AVG(cast(nrep2_t09 - nrep2_t1  as float)/nullif(nrep2,0)) as avg_nrep2_f09,
    AVG(cast(nrep2_t1              as float)/nullif(nrep2,0)) as avg_nrep2_f1
FROM taxparent INNER JOIN af
ON taxparent.tax = af.taxon
WHERE af.meanplddt > 70 and (
    taxparent.rankp = 'species' OR
    taxparent.rankp = 'genus'   OR
    taxparent.rankp = 'family'  OR
    taxparent.rankp = 'order'   OR
    taxparent.rankp = 'class'   OR
    taxparent.rankp = 'phylum'  OR
    taxparent.rankp = 'kingdom'
)
GROUP BY parent, rankp;
