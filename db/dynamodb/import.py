#!/usr/bin/env python3
import orjson, gzip
import boto3 as bo

ddb = bo.client('dynamodb', endpoint_url='http://localhost:8000')
response = ddb.list_tables()
print(response)

table = ddb.create_table(
    TableName='AFProt',
    # specifiy field to uniquely identify table entry.
    # https://gist.github.com/jlafon/d8f91086e3d00c4bff3b
    KeySchema=[
        {
            'AttributeName': 'acc',
            'KeyType': 'HASH'
        }
    ],
    # specifiy schema
    # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/customizations/dynamodb.html#ref-valid-dynamodb-types
    AttributeDefinitions=[
        {
            'AttributeName': 'acc',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'n',
            'AttributeType': 'N'
        },
        {
            'AttributeName': 'x',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'y',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'z',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'cent1',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'cent2',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'bars1',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'bars2',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'persistence',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'reps1',
            'AttributeType': 'L'
        },
        {
            'AttributeName': 'reps2',
            'AttributeType': 'L'
        },
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    }
)

# Wait until the table exists.
table.wait_until_exists()

# Print out some data about the table.
print(table.item_count)

