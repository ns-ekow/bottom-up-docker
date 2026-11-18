# In a new PID namespace, an orphan is adopted by PID 1. If PID 1 never waits for it, it stays a
# zombie after it ends; it disappears only once PID 1 waits for any child.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
gcc -O0 -o "$T/pid1" c/pid1_orphans.c
unshare --pid --fork --mount-proc "$T/pid1"
