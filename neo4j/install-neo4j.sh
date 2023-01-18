#!/usr/bin/env zsh
# neo4j was installed on oracle cloud like this.
sudo rpm --import https://debian.neo4j.com/neotechnology.gpg.key
sudo cp neo4j.repo /etc/yum.repos.d/
NEO4J_ACCEPT_LICENSE_AGREEMENT=yes sudo yum install neo4j-enterprise-5.3.0

