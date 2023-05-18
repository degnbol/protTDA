#!/usr/bin/env zsh

# since there is no couchdb for this cent OS RHEL whatever aarch64 we install from source

# select source at
# https://couchdb.apache.org/#download
wget https://dlcdn.apache.org/couchdb/source/3.3.1/apache-couchdb-3.3.1.tar.gz
tar xzf apache-couchdb-*.tar.gz
cd apache-couchdb-*/

# README leads to INSTALL.unix.md

# one dependency (libmozjs-60-dev) cannot be found
sudo yum -y install autoconf autoconf-archive automake \
    erlang-asn1 erlang-erts erlang-eunit erlang-xmerl \
    libicu-devel libtool perl-Test-Harness \
    python3

sudo yum install -y python-pip
sudo pip install -y --upgrade sphinx nose requests hypothesis

./configure
make release
# doesn't work, maybe try docker
# https://github.com/apache/couchdb-docker
