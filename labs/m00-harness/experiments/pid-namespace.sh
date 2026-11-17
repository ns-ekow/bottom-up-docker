# A new PID namespace: the first process inside sees itself as PID 1 and sees only its own
# descendants. (An earlier version counted processes via $(ps | wc -l) and expected 2; it got 4,
# because the command substitution's subshell and wc are processes too. Experiments win.)
unshare --pid --fork --mount-proc sh -c 'echo "inside: pid=$$"; ps -e -o pid=,comm='
