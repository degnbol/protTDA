#!/usr/bin/env zsh
ROOT=`git root`
# commented out to add to existing tmux session
# tmux new -n query
tmux neww -n query
tmux send-keys './query_speed.js | tee query_speed.js.out' Enter

