#!/usr/bin/env zsh
# This can be run instead of simply `neo4j start` in case the env home is not set.
NEO4J_HOME=$HOME/protTDA/neo4j NEO4J_CONF=$NEO4J_HOME/conf neo4j start
