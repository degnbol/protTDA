\dt
\d af
drop table af;
select * from af;

DELETE FROM tax
    WHERE substring(acc, 3, 1) = '_';

create table aftax as
select tax, af.* from
tax inner join af on tax.acc = af.acc;

SELECT count(distinct acc) FROM tax;

