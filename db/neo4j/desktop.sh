#!/usr/bin/env zsh
# Uncommented line in conf/neo4j.conf:
# server.default_listen_address=0.0.0.0
# Then a port was opened in oracle cloud settings according to
# https://cleavr.io/cleavr-slice/opening-port-80-and-443-for-oracle-servers/
# I.e.
# go to running instance AF2
# click on the VCN
# Click security lists
# Click the default security list
# Add Ingress Rules
# Source CIDR = 0.0.0.0/0 and Destination Port Range 7687 and description Neo4j
# Then 
# iptables -I INPUT -m state --state NEW -p tcp --dport 7687 -j ACCEPT
# Although it didn't seem to have an effect. Then:

sudo firewall-cmd --add-port=7687/tcp
# Then the port was shown as open on a tool such as:
# https://www.yougetsignal.com/tools/open-ports/

# Then open Neo4j desktop locally and press Add arrow -> Remote connection
# Give it a name, Connect URL = neo4j://opc@168.138.0.242:7687
# Press Next then username = neo4j, password = cdmadsen
