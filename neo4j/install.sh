#!/usr/bin/env zsh
# neo4j was installed on oracle cloud like this.
sudo rpm --import https://debian.neo4j.com/neotechnology.gpg.key
sudo cp neo4j.repo /etc/yum.repos.d/
NEO4J_ACCEPT_LICENSE_AGREEMENT=yes sudo yum install neo4j-enterprise-5.3.0

cp -r /var/lib/neo4j/labs/ .
cp -r /var/lib/neo4j/products/ .
mv labs/apoc*.jar plugins/ # as per labs/README.txt

# for apoc.load.directory
apocExtUrl='https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/5.3.0/apoc-5.3.0-extended.jar'
wget $apocExtUrl -O plugins/apoc-5.3.0-extended.jar


ROOT=`git root`
NEO4J_HOME=$ROOT/neo4j NEO4J_CONF=$NEO4J_HOME/conf neo4j-admin dbms set-initial-password cdmadsen

echo 'source $HOME/protTDA/neo4j/env.sh' >> ~/.zshrc
