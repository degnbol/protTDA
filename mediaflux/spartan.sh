# https://rcs-knowledge-hub.atlassian.net/wiki/spaces/KB/pages/5473188/Mediaflux+on+Spartan+HPC
module load unimelb-mf-clients
# https://rcs-knowledge-hub.atlassian.net/wiki/spaces/KB/pages/5474270/Mediaflux+Unimelb+Command-Line+Clients
unimelb-mf-download --mf.config mflux.cfg --nb-workers 4 --out /home/cdmadsen/protTDA/data/alphafold/ /projects/proj-6300_prottda-1128.4.705/Postgres

cd /home/cdmadsen/protTDA/data/alphafold/
# to be consistent with naming used on oracle
mv Postgres PG
# correct permissions, otherwise you get an error when doing `pg_ctl -D ./PG -l PG.log start`
chmod 750 PG

# get error with same command if these folders aren't present
mkdir -p PG/pg_{commit_ts,snapshots,replslot,notify,tblspc}
