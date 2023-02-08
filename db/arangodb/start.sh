sudo sysctl -w "vm.max_map_count=10240000"
numactl --interleave=all sudo arangod --rocksdb.max-background-jobs 36 > server.log
