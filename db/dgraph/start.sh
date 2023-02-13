# https://dgraph.io/docs/installation/single-host-setup/
# dgraph zero --my=168.138.0.242:5080
#
# dgraph alpha --my=168.138.0.242:7080 --zero=localhost:5080
# dgraph alpha --my=168.138.0.242:7081 --zero=localhost:5080 -o=1

sudo docker compose up
