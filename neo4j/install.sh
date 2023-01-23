#!/usr/bin/env zsh
# neo4j was installed on oracle cloud like this.
sudo rpm --import https://debian.neo4j.com/neotechnology.gpg.key
sudo cp neo4j.repo /etc/yum.repos.d/
sudo NEO4J_ACCEPT_LICENSE_AGREEMENT=yes yum install neo4j-enterprise-5.3.0

ln -s ../data/alphafold/PH/neo4j/ neo4j

# shows that license has been accepted:
cp -r /var/lib/neo4j/licenses/ neo4j/
cp -r /var/lib/neo4j/data neo4j/
cp -r /var/lib/neo4j/labs/ neo4j/
cp -r /var/lib/neo4j/products/ neo4j/
mkdir -p neo4j/plugins/
cp neo4j/labs/apoc*.jar neo4j/plugins/ # as per labs/README.txt

# for apoc.load.directory
apocExtUrl='https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/5.3.0/apoc-5.3.0-extended.jar'
wget $apocExtUrl -O neo4j/plugins/apoc-5.3.0-extended.jar

ROOT=`git root`
NEO4J_HOME=$ROOT/neo4j/neo4j/ NEO4J_CONF=$ROOT/neo4j/conf neo4j-admin dbms set-initial-password cdmadsen

echo 'source $HOME/protTDA/neo4j/env.sh' >> ~/.zshrc

