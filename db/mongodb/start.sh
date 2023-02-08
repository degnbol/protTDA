#!/usr/bin/env zsh
ROOT=`git root`
# NOTE: https://www.mongodb.com/docs/manual/reference/ulimit/
# After starting mongosh I get the warning:
# You are running on a NUMA machine. We suggest launching mongod like this to avoid performance problems: numactl --interleave=all mongod [other options]
# sudo bin/mongod --dbpath $ROOT/xfs/mongo --bind_ip_all > server.log &
ulimit -n 65536
sudo numactl --interleave=all bin/mongod --dbpath $ROOT/xfs/mongo --bind_ip_all > server.log
