tmux new -n mongo
tmux send-keys './start.sh &' Enter
tmux send-keys 'mongosh' Enter
tmux send-keys 'use protTDA' Enter
tmux send-keys 'db.createCollection("AF")' Enter
tmux splitw
tmux send-keys 'julia' Enter
tmux send-keys 'include("mongo.jl")' Enter
