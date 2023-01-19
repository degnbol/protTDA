#!/usr/bin/env zsh
# neo4j was installed on oracle cloud like this.
sudo rpm --import https://debian.neo4j.com/neotechnology.gpg.key
sudo cp neo4j.repo /etc/yum.repos.d/
NEO4J_ACCEPT_LICENSE_AGREEMENT=yes sudo yum install neo4j-enterprise-5.3.0

cp -r /var/lib/neo4j/labs/ .
cp -r /var/lib/neo4j/products/ .

ROOT=`git root`
NEO4J_HOME=$ROOT/neo4j NEO4J_CONF=$NEO4J_HOME/conf neo4j-admin dbms set-initial-password cdmadsen

echo 'source $HOME/protTDA/neo4j/env.sh' >> ~/.zshrc
