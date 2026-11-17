# A new PID namespace: the first process inside sees itself as PID 1 and sees only its own
# descendants. List the processes rather than counting them with $(ps | wc -l): the command
# substitution's subshell and wc would be counted too.
unshare --pid --fork --mount-proc sh -c 'echo "inside: pid=$$"; ps -e -o pid=,comm='
