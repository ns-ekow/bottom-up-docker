# Runs zombies.sh ($LAB_IMPL: starter or solution) while a known zombie exists, and checks that it
# reports that zombie with its parent's PID and command. Exit 0 = pass.
IMPL=${LAB_IMPL:-starter}
sh -c 'sleep 0.1 & exec sleep 3' &          # its child finishes and is never waited for
parent=$!; sleep 0.5
zombie=$(ps -o pid= --ppid "$parent" | tr -d ' ')
out=$(bash "$IMPL/zombies.sh")
wait "$parent" || true
if echo "$out" | grep -qx "$zombie $parent sleep"; then echo "ok    zombies.sh reports zombie $zombie (parent $parent, sleep)"
else echo "FAIL  zombies.sh did not report \"$zombie $parent sleep\"; it printed:"; echo "$out" | sed 's/^/      /'; exit 1; fi
