
-- 33208 is metazoa, i.e. animals.
-- 3193 is Embryophyta (land plants).
-- We join on taxtree to not just have tax for species, but also their subspecies etc. which adds a few more taxons.
create table multicell as
select
    taxparent.parent as ancestor,
    taxparent.tax as species,
    taxtree.tax as tax,
    taxtree.rank as rank
from taxparent inner join taxtree
on taxtree.parent = taxparent.tax
where (taxparent.parent = 33208 or taxparent.parent = 3193)
and taxparent.rank = 'species';

-- DROP TABLE pern_multicell;
CREATE TABLE pern_multicell as
SELECT pern.*, multicell.ancestor
FROM multicell INNER JOIN pern ON pern.tax = multicell.tax;

CREATE TABLE pern_unicell as
SELECT P.*
FROM pern P
WHERE domain = 'E'
and NOT EXISTS (SELECT 1 FROM multicell M WHERE P.tax = M.tax);

-- A sanity check was performed checking the number of entries in pern_multicell + pern_unicell = pern domain E, as measured by
-- select count(*) from pern where domain = 'E';
-- 21110897 + 10136290 = 31247187

-- concat
CREATE OR REPLACE VIEW pern_E AS
SELECT a.*,
    TRUE AS multicell
FROM pern_multicell a
UNION ALL
SELECT b.*,
    -1 AS ancestor,
    FALSE AS multicell
FROM pern_unicell b;

create table nrep1_hist_E as
select width_bucket(nrep1, 0, 3.7142857142857143, 1000) as bucket,
    multicell,
    count(*) as freq,
    sum(weight) as weighted
from pern_E inner join taxweight on pern_E.tax = taxweight.tax
group by bucket, multicell
order by bucket;

create table nrep2_hist_E as
select width_bucket(nrep2, 0, 2.9665178571428571, 1000) as bucket,
    multicell,
    count(*) as freq,
    sum(weight) as weighted
from pern_E inner join taxweight on pern_E.tax = taxweight.tax
group by bucket, multicell
order by bucket;

create table maxrep1_hist_E as
select width_bucket(maxrep1, 0, 1.0089285714285714, 1000) as bucket,
    multicell,
    count(*) as freq,
    sum(weight) as weighted
from pern_E inner join taxweight on pern_E.tax = taxweight.tax
group by bucket, multicell
order by bucket;

create table maxrep2_hist_E as
select width_bucket(maxrep2, 0, 1.4285714285714286, 1000) as bucket,
    multicell,
    count(*) as freq,
    sum(weight) as weighted
from pern_E inner join taxweight on pern_E.tax = taxweight.tax
group by bucket, multicell
order by bucket;

create table richness_hist_E as
select width_bucket(richness, -3.42340972773309342803, -1.43136376415898731185, 1000) as bucket,
    multicell,
    count(*) as freq,
    sum(weight) as weighted
from pern_E inner join taxweight on pern_E.tax = taxweight.tax
group by bucket, multicell
order by bucket;

alter table nrep1_hist_E     add H INTEGER;
alter table nrep2_hist_E     add H INTEGER;
alter table maxrep1_hist_E   add H INTEGER;
alter table maxrep2_hist_E   add H INTEGER;
alter table richness_hist_E  add H INTEGER;
alter table nrep1_hist_E     add meas VARCHAR(8);
alter table nrep2_hist_E     add meas VARCHAR(8);
alter table maxrep1_hist_E   add meas VARCHAR(8);
alter table maxrep2_hist_E   add meas VARCHAR(8);
alter table richness_hist_E  add meas VARCHAR(8);

update nrep1_hist_E     set H=1;
update nrep2_hist_E     set H=2;
update maxrep1_hist_E   set H=1;
update maxrep2_hist_E   set H=2;
update richness_hist_E  set H=1;
update nrep1_hist_E     set meas='nrep';
update nrep2_hist_E     set meas='nrep';
update maxrep1_hist_E   set meas='maxrep';
update maxrep2_hist_E   set meas='maxrep';
update richness_hist_E  set meas='richness';

-- drop table hist_E;
CREATE table hist_E AS
  SELECT * FROM nrep1_hist_E
  UNION ALL
  SELECT * FROM nrep2_hist_E
  UNION ALL
  SELECT * FROM maxrep1_hist_E
  UNION ALL
  SELECT * FROM maxrep2_hist_E
  UNION ALL
  SELECT * FROM richness_hist_E;

drop table nrep1_hist_E, nrep2_hist_E, maxrep1_hist_E, maxrep2_hist_E, richness_hist_E;

\copy hist_E to 'hist_E.csv' csv header;

