#!/usr/bin/env zsh
# https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-red-hat-tarball/
wget https://fastdl.mongodb.org/src/mongodb-src-r6.0.4.tar.gz
tar zxf mongodb-*.tar.gz
cd mongodb-*/

# requirements
# mongodb-src-r6.0.4/docs/building.md
sudo yum install libcurl libcurl-devel openssl xz-libs
sudo dnf install python3-devel openssl-devel

# python req
mamba create -yn mongo python
mamba activate mongo
python3 -m pip install -r etc/pip/compile-requirements.txt

# build
python3 buildscripts/scons.py DESTDIR=../ --disable-warnings-as-errors

# shell is prebuilt for Aarch64, redhat 9, etc. etc. versions etc.
# https://www.mongodb.com/docs/mongodb-shell/install/
sudo cp mongodb-org-6.0.repo /etc/yum.repos.d/mongodb-org-6.0.repo
sudo yum install -y mongodb-mongosh

# After starting mongosh I get the warning:
# You are running on a NUMA machine. We suggest launching mongod like this to avoid performance problems: numactl --interleave=all mongod [other options]
sudo yum install -y numactl

# mongoimport comes in the database tools.
# The newest version of those for Aarch64 (ARM) and newest version of redhat is
# https://www.mongodb.com/download-center/database-tools/releases/archive
wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel82-arm64-100.6.1.rpm
sudo yum install -y ./mongodb-database-tools*.rpm

# create database and collection
./install.mgsh
