# history of tmux calls.
for i in {1..120}; do
    tmux neww -d 'for i in {1..10}; do ./ripsererAF.jl; done'
done
