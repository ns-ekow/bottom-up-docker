# fork, exec, wait as the kernel sees them: glibc's fork() is the clone system call; the child then
# runs execve; the parent's waitpid is the wait4 system call, which returns once the child exits.
# A file opened normally stays open across exec; one opened close-on-exec does not.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
gcc -O0 -o "$T/few" c/fork_exec_wait.c
strace -f -o "$T/trace" -e trace=clone,clone3,execve,wait4,exit_group "$T/few" > "$T/out"
echo "== program output"; cat "$T/out"
echo "== system calls (first pid seen = parent)"
awk '!($1 in who) { who[$1] = (n++ ? "child " : "parent") } { $1 = who[$1] ":"; print }' "$T/trace" \
  | grep -v '+++' | sed "s#$T#TMP#g; s/0x[0-9a-f]*/0x…/g"
