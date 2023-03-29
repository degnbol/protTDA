sudo sysctl -w "vm.max_map_count=10240000"
numactl --interleave=all sudo arangod --configuration arangod.conf
