# Docker install
# https://dgraph.io/docs/installation/single-host-setup/
# sudo yum install -y docker
# including composer
# https://docs.docker.com/engine/install/centos
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# the docker pull call will fail if docker daemon is not running.
sudo systemctl start docker

# take second option (not oracle) at the prompt. Oracle option gives error.
sudo docker pull dgraph/dgraph:latest
sudo docker images

# docker-compose.yml was edited after download from:
# wget https://github.com/dgraph-io/dgraph/raw/main/contrib/config/docker/docker-compose.yml

