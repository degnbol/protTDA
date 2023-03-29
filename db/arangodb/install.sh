https://www.arangodb.com/download-major/centos/
wget https://download.arangodb.com/arangodb310/Community/Linux/arangodb3-3.10.3-1.0.aarch64.rpm
sudo yum install arangodb3-3.10.3-1.0.aarch64.rpm

mamba create -n arango python ipython python-arango
mamba activate arango

