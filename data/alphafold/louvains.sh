#!/usr/bin/env zsh
for i in {1..20}; do
    tmux neww
    tmux send-keys 'for i in {1..10}; do ./louvains.py; done' Enter
done

