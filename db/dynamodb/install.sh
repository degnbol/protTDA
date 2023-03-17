#!/usr/bin/env zsh
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.DownloadingAndRunning.html
wget https://s3.ap-southeast-1.amazonaws.com/dynamodb-local-singapore/dynamodb_local_latest.tar.gz
tar xzf dynamodb_local_latest.tar.gz
# the local path to put db in has to exist otherwise we get error
mkdir db

# install aws to interact with db
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds
echo "typed root root us-west-2 json"
aws configure

# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.CLI.html

# AWS SDK
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Using.API.html
conda create -yn dynamodb python ipython numpy orjson
conda activate dynamodb
pip install boto3

