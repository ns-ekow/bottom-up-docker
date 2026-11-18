# Why `docker stop` can take ten seconds: sleep, running as the container's PID 1, has no SIGTERM
# handler, so the SIGTERM docker stop sends is ignored. After its timeout Docker sends SIGKILL.
# containerd's shim, the container's parent, then collects the exit with wait4 and reports 128+9.
docker image inspect busybox:1.37 >/dev/null 2>&1 || docker pull -q busybox:1.37 >/dev/null
id=$(docker run -d busybox:1.37 sleep 300); trap 'docker rm -f "$id" >/dev/null 2>&1' EXIT
sleep 1
cpid=$(docker inspect -f '{{.State.Pid}}' "$id"); shim=$(ps -o ppid= -p "$cpid" | tr -d ' ')
echo "the container's PID 1 has parent: $(ps -o comm= -p "$shim")"
T=$(mktemp); strace -f -p "$shim" -e trace=wait4 -o "$T" 2>/dev/null & S=$!; sleep 1
start=$(date +%s); docker stop "$id" >/dev/null; took=$(( $(date +%s) - start ))
sleep 1; kill "$S" 2>/dev/null || true; wait "$S" 2>/dev/null || true   # strace may already have exited
echo "docker stop took ${took}s"
# strace prints a call interrupted by another thread in two parts ("wait4(-1 <unfinished ...>", then
# "<... wait4 resumed>, ..."), so match either form and print it as one line.
grep -E "(wait4\(-1|<\.\.\. wait4 resumed>).*\) = $cpid$" "$T" | head -1 \
  | sed -E 's/^[0-9]+ +//; s/^<\.\.\. wait4 resumed>/wait4(-1/; s/, \{ru_utime.*\}\)/, …)/'
echo "docker reports: $(docker inspect -f 'ExitCode={{.State.ExitCode}}' "$id")"
rm -f "$T"
