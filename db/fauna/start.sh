#!/usr/bin/env zsh
# https://medium.com/fauna/setting-up-a-new-fauna-cluster-using-docker-bb43f5c5ca5
sudo docker run --rm --name faunadb -p 8443:8443 \
    -v ./db:/var/lib/faunadb -v ./db:/var/log/faunadb \
    fauna/faunadb
