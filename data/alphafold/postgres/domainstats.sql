CREATE TABLE pern as
SELECT
    domain,
    acc,
    af.tax,
    nrep1::numeric/n     as nrep1,
    nrep1_t10::numeric/n as nrep1_t10,
    nrep2::numeric/n     as nrep2,
    maxrep1::numeric/n   as maxrep1,
    maxrep2::numeric/n   as maxrep2,
    maxpers1::numeric/n  as maxpers1,
    maxpers2::numeric/n  as maxpers2
FROM taxtree INNER JOIN af ON af.tax = taxtree.tax
WHERE taxtree.rankp = 'species' and af.meanplddt > 70;

CREATE TABLE speciespern as
SELECT
    domain,
    tax,
    AVG(nrep1) as nrep1,
    AVG(nrep2) as nrep2,
    AVG(maxrep1) as maxrep1,
    AVG(maxrep2) as maxrep2,
    AVG(maxpers1) as maxpers1,
    AVG(maxpers2) as maxpers2
FROM pern
GROUP BY tax, domain;

SELECT
    domain,
    AVG(nrep1) as nrep1,
    AVG(nrep2) as nrep2,
    AVG(maxrep1) as maxrep1,
    AVG(maxrep2) as maxrep2,
    AVG(maxpers1) as maxpers1,
    AVG(maxpers2) as maxpers2
FROM speciespern
GROUP BY domain;

-- we can see avg of avg (species weighted) fits what we have seen before
DROP TABLE speciespern;

create table taxweight as
select tax, 1::numeric/count(*) as weight from pern
group by tax;

create table hist_maxs as
select
    max(nrep1) as nrep1_max,
    max(nrep1_t10) as nrep1_t10_max,
    max(nrep2) as nrep2_max,
    max(maxrep1) as maxrep1_max,
    max(maxrep2) as maxrep2_max
from pern;

-- copy from these values for the max bucket ranges below
select * from hist_maxs;

create table nrep1_hist as
select width_bucket(nrep1, 0, 3.7142857142857143, 1000) as bucket,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern inner join taxweight on pern.tax = taxweight.tax
group by bucket, domain
order by bucket;

create table nrep1_t10_hist as
select width_bucket(nrep1_t10, 0, 0.03703703703703703704, 1000) as bucket,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern inner join taxweight on pern.tax = taxweight.tax
group by bucket, domain
order by bucket;

create table nrep2_hist as
select width_bucket(nrep2, 0, 2.9665178571428571, 1000) as bucket,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern inner join taxweight on pern.tax = taxweight.tax
group by bucket, domain
order by bucket;

create table maxrep1_hist as
select width_bucket(maxrep1, 0, 1.0089285714285714, 1000) as bucket,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern inner join taxweight on pern.tax = taxweight.tax
group by bucket, domain
order by bucket;

create table maxrep2_hist as
select width_bucket(maxrep2, 0, 1.4285714285714286, 1000) as bucket,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern inner join taxweight on pern.tax = taxweight.tax
group by bucket, domain
order by bucket;

alter table nrep1_hist     add H INTEGER;
alter table nrep1_t10_hist add H INTEGER;
alter table nrep2_hist     add H INTEGER;
alter table maxrep1_hist   add H INTEGER;
alter table maxrep2_hist   add H INTEGER;
alter table nrep1_hist     add meas VARCHAR(8);
alter table nrep1_t10_hist add meas VARCHAR(8);
alter table nrep2_hist     add meas VARCHAR(8);
alter table maxrep1_hist   add meas VARCHAR(8);
alter table maxrep2_hist   add meas VARCHAR(8);

update nrep1_hist     set H=1;
update nrep1_t10_hist set H=1;
update nrep2_hist     set H=2;
update maxrep1_hist   set H=1;
update maxrep2_hist   set H=2;
update nrep1_hist     set meas='nrep';
update nrep1_t10_hist set meas='nrep_t10';
update nrep2_hist     set meas='nrep';
update maxrep1_hist   set meas='maxrep';
update maxrep2_hist   set meas='maxrep';

CREATE table domainhist AS
  SELECT * FROM nrep1_hist
  UNION ALL
  SELECT * FROM nrep1_t10_hist
  UNION ALL
  SELECT * FROM nrep2_hist
  UNION ALL
  SELECT * FROM maxrep1_hist
  UNION ALL
  SELECT * FROM maxrep2_hist;

drop table nrep1_hist, nrep1_t10_hist, nrep2_hist, maxrep1_hist, maxrep2_hist;

\copy domainhist to 'domainhist.csv' csv header;
\copy hist_maxs to 'domainhistmaxs.csv' csv header;

-- remaining code is to write modelshist.csv

create table models (
    label TEXT NOT NULL,
    tax INTEGER PRIMARY KEY
);

\copy models from 'vis/modelOrganisms.tsv' DELIMITER E'\t' CSV HEADER;

CREATE TABLE pern_models AS
SELECT models.label, pern.*
FROM models INNER JOIN pern ON models.tax = pern.tax;

create table nrep1_hist as
select width_bucket(nrep1, 0, 3.7142857142857143, 1000) as bucket,
    label,
    pern_models.tax,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern_models inner join taxweight on pern_models.tax = taxweight.tax
group by bucket, domain, pern_models.tax, label
order by bucket;

create table nrep2_hist as
select width_bucket(nrep2, 0, 2.9665178571428571, 1000) as bucket,
    label,
    pern_models.tax,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern_models inner join taxweight on pern_models.tax = taxweight.tax
group by bucket, domain, pern_models.tax, label
order by bucket;

create table maxrep1_hist as
select width_bucket(maxrep1, 0, 1.0089285714285714, 1000) as bucket,
    label,
    pern_models.tax,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern_models inner join taxweight on pern_models.tax = taxweight.tax
group by bucket, domain, pern_models.tax, label
order by bucket;

create table maxrep2_hist as
select width_bucket(maxrep2, 0, 1.4285714285714286, 1000) as bucket,
    label,
    pern_models.tax,
    domain,
    count(*) as freq,
    sum(weight) as weighted
from pern_models inner join taxweight on pern_models.tax = taxweight.tax
group by bucket, domain, pern_models.tax, label
order by bucket;

alter table nrep1_hist   add H INTEGER;
alter table nrep2_hist   add H INTEGER;
alter table maxrep1_hist add H INTEGER;
alter table maxrep2_hist add H INTEGER;
alter table nrep1_hist   add meas VARCHAR(6);
alter table nrep2_hist   add meas VARCHAR(6);
alter table maxrep1_hist add meas VARCHAR(6);
alter table maxrep2_hist add meas VARCHAR(6);

update nrep1_hist   set H=1;
update nrep2_hist   set H=2;
update maxrep1_hist set H=1;
update maxrep2_hist set H=2;
update nrep1_hist   set meas='nrep';
update nrep2_hist   set meas='nrep';
update maxrep1_hist set meas='maxrep';
update maxrep2_hist set meas='maxrep';

-- DROP TABLE modelshist;
CREATE table modelshist AS
  SELECT * FROM nrep1_hist
  UNION ALL
  SELECT * FROM nrep2_hist
  UNION ALL
  SELECT * FROM maxrep1_hist
  UNION ALL
  SELECT * FROM maxrep2_hist;

drop table nrep1_hist, nrep2_hist, maxrep1_hist, maxrep2_hist;

\copy modelshist to 'modelshist.csv' csv header;
