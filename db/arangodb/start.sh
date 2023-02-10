sudo sysctl -w "vm.max_map_count=10240000"
numactl --interleave=all arangod --configuration arangod.conf > server.log
