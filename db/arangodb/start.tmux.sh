tmux new -dn arango
tmux send-keys './start.sh' Enter
tmux splitw
tmux send-keys 'arangosh --server.password ""' Enter
# tmux send-keys 'db._dropDatabase("protTDA")' Enter
# tmux send-keys 'db._createDatabase("protTDA")' Enter
tmux send-keys 'db._useDatabase("protTDA")' Enter
# tmux send-keys 'db._drop("AF")' Enter
# tmux send-keys 'db._create("AF")' Enter
