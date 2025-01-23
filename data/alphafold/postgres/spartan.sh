#!/usr/bin/env zsh
module load foss/2022a
module load PostgreSQL/15.2

pg_ctl -D ./PG -l PG.log start

psql --dbname=protTDA --username=opc

pg_ctl -D ./PG stop
