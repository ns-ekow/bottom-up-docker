# A finished child whose parent never waits for it stays in the process table as a zombie (state Z).
# Here the parent replaces itself with `sleep 2` (exec keeps the process), and sleep never waits.
sh -c 'sleep 0.2 & exec sleep 2' &
parent=$!
sleep 0.6
ps -o pid,ppid,stat,comm --ppid "$parent" --no-headers | awk '{print "child of", $2, "state", $3, $4}'
z=$(ps -o pid= --ppid "$parent" | tr -d ' ')
grep '^State:' /proc/"$z"/status
wait "$parent"
