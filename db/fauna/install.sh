# self hosting with docker
sudo docker pull fauna/faunadb:latest

# https://dev.to/englishcraig/how-to-set-up-faunadb-for-local-development-5ha7
sudo npm i -g fauna-shell
fauna add-endpoint http://localhost:8443/ --alias localhost --key secret
fauna default-endpoint localhost
fauna create-database development_db --endpoint=localhost
echo -n "FAUNADB_KEY=" > .env
fauna create-key development_db --endpoint=localhost |
    grep secret: | cut -f2 -d: | xargs >> .env

# completion install instructions
fauna autocomplete zsh

# https://docs.scala-lang.org/getting-started/index.html
curl -fL https://github.com/VirtusLab/coursier-m1/releases/latest/download/cs-aarch64-pc-linux.gz | gzip -d > cs && chmod +x cs && ./cs setup
# make scala 2 project 
sbt new scala/hello-world.g8
# selected fauna as project name

# python driver
# https://docs.fauna.com/fauna/current/drivers/python
conda create -n faunadb python=3.9 ipython orjson
conda activate faunadb
pip install faunadb

