#!/usr/bin/env zsh
tmux new -d './louvains.zsh'
for i in {1..157}; do
    tmux neww -d './louvains.zsh'
done

