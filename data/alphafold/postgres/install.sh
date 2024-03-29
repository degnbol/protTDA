#!/usr/bin/env zsh
# mac install for later local usage, linux install for oracle server
if [ `uname` = "Darwin" ]; then
    brew install postgresql@15
else
    wget https://ftp.postgresql.org/pub/source/v15.2/postgresql-15.2.tar.gz
    tar xzf postgresql-15.2.tar.gz && rm postgresql-15.2.tar.gz
    cd ./postgresql-15.2
    # reading INSTALL
    sudo yum install -y readline-devel
    ./configure --prefix=/home/opc/protTDA/bin/postgresql
    make
    sudo make install

    # init db
    cd -
    `git root`/bin/postgresql/bin/initdb ./PG

    `git root`/bin/postgresql/bin/pg_ctl -D ./PG -l PH.log start
    export PATH="$PATH:`git root`/bin/postgresql/bin"
    echo "export PATH=\$PATH:`git root`/bin/postgresql/bin"
    createdb protTDA
    # interactive shell
    psql --dbname=protTDA
fi

# install the julia package libPQ
$0:h/install.jl

