#!/usr/bin/env zsh
ps aux | grep neo4j | grep -v grep | sed 's/opc *//' | cut -f1 -d ' ' | xargs kill -9
