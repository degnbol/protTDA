create table treeedge as
select p.tax as parent, c.tax as child,
    cast(c.proteins as float)/NULLIF(p.proteins,0) as proteins_f,
    c.avg_n/NULLIF(p.avg_n,0) as avg_n_f,
    c.avg_maxpers1/NULLIF(p.avg_maxpers1,0) as avg_maxpers1_f,
    c.avg_maxpers2/NULLIF(p.avg_maxpers2,0) as avg_maxpers2_f,
    c.avg_nrep1/NULLIF(p.avg_nrep1,0) as avg_nrep1_f,
    c.avg_nrep2/NULLIF(p.avg_nrep2,0) as avg_nrep2_f,
    c.var_n/NULLIF(p.var_n,0) as var_n_f,
    c.var_maxpers1/NULLIF(p.var_maxpers1,0) as var_maxpers1_f,
    c.var_maxpers2/NULLIF(p.var_maxpers2,0) as var_maxpers2_f,
    c.var_nrep1/NULLIF(p.var_nrep1,0) as var_nrep1_f,
    c.var_nrep2/NULLIF(p.var_nrep2,0) as var_nrep2_f,
    ARRAY[c.avg_nrep1_b0,
          c.avg_nrep1_b1,
          c.avg_nrep1_b2,
          c.avg_nrep1_b3,
          c.avg_nrep1_b4,
          c.avg_nrep1_b5,
          c.avg_nrep1_b6,
          c.avg_nrep1_b7,
          c.avg_nrep1_b8,
          c.avg_nrep1_b9,
          c.avg_nrep1_t10] as c_nrep1_b,
    ARRAY[p.avg_nrep1_b0,
          p.avg_nrep1_b1,
          p.avg_nrep1_b2,
          p.avg_nrep1_b3,
          p.avg_nrep1_b4,
          p.avg_nrep1_b5,
          p.avg_nrep1_b6,
          p.avg_nrep1_b7,
          p.avg_nrep1_b8,
          p.avg_nrep1_b9,
          p.avg_nrep1_t10] as p_nrep1_b,
    ARRAY[c.avg_nrep2_b00,
          c.avg_nrep2_b01,
          c.avg_nrep2_b02,
          c.avg_nrep2_b03,
          c.avg_nrep2_b04,
          c.avg_nrep2_b05,
          c.avg_nrep2_b06,
          c.avg_nrep2_b07,
          c.avg_nrep2_b08,
          c.avg_nrep2_b09,
          c.avg_nrep2_t1] as c_nrep2_b,
    ARRAY[p.avg_nrep2_b00,
          p.avg_nrep2_b01,
          p.avg_nrep2_b02,
          p.avg_nrep2_b03,
          p.avg_nrep2_b04,
          p.avg_nrep2_b05,
          p.avg_nrep2_b06,
          p.avg_nrep2_b07,
          p.avg_nrep2_b08,
          p.avg_nrep2_b09,
          p.avg_nrep2_t1] as p_nrep2_b
from treenode c
inner join taxtree e on c.tax = e.tax
inner join treenode p on p.tax = e.parent
where c.tax != p.tax;

create table treeedge_perprot as
select p.tax as parent, c.tax as child,
    cast(c.proteins as float)/NULLIF(p.proteins,0) as proteins_f,
    c.avg_n/NULLIF(p.avg_n,0) as avg_n_f,
    c.avg_maxpers1/NULLIF(p.avg_maxpers1,0) as avg_maxpers1_f,
    c.avg_maxpers2/NULLIF(p.avg_maxpers2,0) as avg_maxpers2_f,
    c.avg_nrep1/NULLIF(p.avg_nrep1,0) as avg_nrep1_f,
    c.avg_nrep2/NULLIF(p.avg_nrep2,0) as avg_nrep2_f,
    c.var_n/NULLIF(p.var_n,0) as var_n_f,
    c.var_maxpers1/NULLIF(p.var_maxpers1,0) as var_maxpers1_f,
    c.var_maxpers2/NULLIF(p.var_maxpers2,0) as var_maxpers2_f,
    c.var_nrep1/NULLIF(p.var_nrep1,0) as var_nrep1_f,
    c.var_nrep2/NULLIF(p.var_nrep2,0) as var_nrep2_f,
    ARRAY[c.avg_nrep1_b0,
          c.avg_nrep1_b1,
          c.avg_nrep1_b2,
          c.avg_nrep1_b3,
          c.avg_nrep1_b4,
          c.avg_nrep1_b5,
          c.avg_nrep1_b6,
          c.avg_nrep1_b7,
          c.avg_nrep1_b8,
          c.avg_nrep1_b9,
          c.avg_nrep1_t10] as c_nrep1_b,
    ARRAY[p.avg_nrep1_b0,
          p.avg_nrep1_b1,
          p.avg_nrep1_b2,
          p.avg_nrep1_b3,
          p.avg_nrep1_b4,
          p.avg_nrep1_b5,
          p.avg_nrep1_b6,
          p.avg_nrep1_b7,
          p.avg_nrep1_b8,
          p.avg_nrep1_b9,
          p.avg_nrep1_t10] as p_nrep1_b,
    ARRAY[c.avg_nrep2_b00,
          c.avg_nrep2_b01,
          c.avg_nrep2_b02,
          c.avg_nrep2_b03,
          c.avg_nrep2_b04,
          c.avg_nrep2_b05,
          c.avg_nrep2_b06,
          c.avg_nrep2_b07,
          c.avg_nrep2_b08,
          c.avg_nrep2_b09,
          c.avg_nrep2_t1] as c_nrep2_b,
    ARRAY[p.avg_nrep2_b00,
          p.avg_nrep2_b01,
          p.avg_nrep2_b02,
          p.avg_nrep2_b03,
          p.avg_nrep2_b04,
          p.avg_nrep2_b05,
          p.avg_nrep2_b06,
          p.avg_nrep2_b07,
          p.avg_nrep2_b08,
          p.avg_nrep2_b09,
          p.avg_nrep2_t1] as p_nrep2_b
from treenode_perprot c
inner join taxtree e on c.tax = e.tax
inner join treenode_perprot p on p.tax = e.parent
where c.tax != p.tax;

create table treeedge_domain as
select
    false as by_protein,
    p.domain as parent, c.tax as child,
    cast(c.proteins as float)/NULLIF(p.proteins,0) as proteins_f,
    c.avg_n/NULLIF(p.avg_n,0) as avg_n_f,
    c.avg_maxpers1/NULLIF(p.avg_maxpers1,0) as avg_maxpers1_f,
    c.avg_maxpers2/NULLIF(p.avg_maxpers2,0) as avg_maxpers2_f,
    c.avg_nrep1/NULLIF(p.avg_nrep1,0) as avg_nrep1_f,
    c.avg_nrep2/NULLIF(p.avg_nrep2,0) as avg_nrep2_f,
    c.var_n/NULLIF(p.var_n,0) as var_n_f,
    c.var_maxpers1/NULLIF(p.var_maxpers1,0) as var_maxpers1_f,
    c.var_maxpers2/NULLIF(p.var_maxpers2,0) as var_maxpers2_f,
    c.var_nrep1/NULLIF(p.var_nrep1,0) as var_nrep1_f,
    c.var_nrep2/NULLIF(p.var_nrep2,0) as var_nrep2_f,
    ARRAY[c.avg_nrep1_b0,
          c.avg_nrep1_b1,
          c.avg_nrep1_b2,
          c.avg_nrep1_b3,
          c.avg_nrep1_b4,
          c.avg_nrep1_b5,
          c.avg_nrep1_b6,
          c.avg_nrep1_b7,
          c.avg_nrep1_b8,
          c.avg_nrep1_b9,
          c.avg_nrep1_t10] as c_nrep1_b,
    ARRAY[p.avg_nrep1_b0,
          p.avg_nrep1_b1,
          p.avg_nrep1_b2,
          p.avg_nrep1_b3,
          p.avg_nrep1_b4,
          p.avg_nrep1_b5,
          p.avg_nrep1_b6,
          p.avg_nrep1_b7,
          p.avg_nrep1_b8,
          p.avg_nrep1_b9,
          p.avg_nrep1_t10] as p_nrep1_b,
    ARRAY[c.avg_nrep2_b00,
          c.avg_nrep2_b01,
          c.avg_nrep2_b02,
          c.avg_nrep2_b03,
          c.avg_nrep2_b04,
          c.avg_nrep2_b05,
          c.avg_nrep2_b06,
          c.avg_nrep2_b07,
          c.avg_nrep2_b08,
          c.avg_nrep2_b09,
          c.avg_nrep2_t1] as c_nrep2_b,
    ARRAY[p.avg_nrep2_b00,
          p.avg_nrep2_b01,
          p.avg_nrep2_b02,
          p.avg_nrep2_b03,
          p.avg_nrep2_b04,
          p.avg_nrep2_b05,
          p.avg_nrep2_b06,
          p.avg_nrep2_b07,
          p.avg_nrep2_b08,
          p.avg_nrep2_b09,
          p.avg_nrep2_t1] as p_nrep2_b
from treenode c
inner join toplevel e on c.tax = e.tax
inner join treenode_domain p on p.domain = e.domain
where p.by_protein = false
UNION ALL
select
    true as by_protein,
    p.domain as parent, c.tax as child,
    cast(c.proteins as float)/NULLIF(p.proteins,0) as proteins_f,
    c.avg_n/NULLIF(p.avg_n,0) as avg_n_f,
    c.avg_maxpers1/NULLIF(p.avg_maxpers1,0) as avg_maxpers1_f,
    c.avg_maxpers2/NULLIF(p.avg_maxpers2,0) as avg_maxpers2_f,
    c.avg_nrep1/NULLIF(p.avg_nrep1,0) as avg_nrep1_f,
    c.avg_nrep2/NULLIF(p.avg_nrep2,0) as avg_nrep2_f,
    c.var_n/NULLIF(p.var_n,0) as var_n_f,
    c.var_maxpers1/NULLIF(p.var_maxpers1,0) as var_maxpers1_f,
    c.var_maxpers2/NULLIF(p.var_maxpers2,0) as var_maxpers2_f,
    c.var_nrep1/NULLIF(p.var_nrep1,0) as var_nrep1_f,
    c.var_nrep2/NULLIF(p.var_nrep2,0) as var_nrep2_f,
    ARRAY[c.avg_nrep1_b0,
          c.avg_nrep1_b1,
          c.avg_nrep1_b2,
          c.avg_nrep1_b3,
          c.avg_nrep1_b4,
          c.avg_nrep1_b5,
          c.avg_nrep1_b6,
          c.avg_nrep1_b7,
          c.avg_nrep1_b8,
          c.avg_nrep1_b9,
          c.avg_nrep1_t10] as c_nrep1_b,
    ARRAY[p.avg_nrep1_b0,
          p.avg_nrep1_b1,
          p.avg_nrep1_b2,
          p.avg_nrep1_b3,
          p.avg_nrep1_b4,
          p.avg_nrep1_b5,
          p.avg_nrep1_b6,
          p.avg_nrep1_b7,
          p.avg_nrep1_b8,
          p.avg_nrep1_b9,
          p.avg_nrep1_t10] as p_nrep1_b,
    ARRAY[c.avg_nrep2_b00,
          c.avg_nrep2_b01,
          c.avg_nrep2_b02,
          c.avg_nrep2_b03,
          c.avg_nrep2_b04,
          c.avg_nrep2_b05,
          c.avg_nrep2_b06,
          c.avg_nrep2_b07,
          c.avg_nrep2_b08,
          c.avg_nrep2_b09,
          c.avg_nrep2_t1] as c_nrep2_b,
    ARRAY[p.avg_nrep2_b00,
          p.avg_nrep2_b01,
          p.avg_nrep2_b02,
          p.avg_nrep2_b03,
          p.avg_nrep2_b04,
          p.avg_nrep2_b05,
          p.avg_nrep2_b06,
          p.avg_nrep2_b07,
          p.avg_nrep2_b08,
          p.avg_nrep2_b09,
          p.avg_nrep2_t1] as p_nrep2_b
from treenode_perprot c
inner join toplevel e on c.tax = e.tax
inner join treenode_domain p on p.domain = e.domain
where p.by_protein = true;

