#!/usr/bin/env zsh
source .env
fauna upload-graphql-schema ./test.gql --mode=override \
    --secret=$FAUNADB_KEY \
    --graphqlPort=8443 --scheme=http --endpoint=localhost --domain=127.0.0.1

