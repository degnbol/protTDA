#!/usr/bin/env zsh
tmux new -d './rips.zsh'
for i in {1..157}; do
    tmux neww -d './rips.zsh'
done

