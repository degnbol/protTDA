cargo init
# error due to missing shared library (.so)
ln -sf $HDF5_DIR/lib/libhdf5.so.200 target/debug/deps/
