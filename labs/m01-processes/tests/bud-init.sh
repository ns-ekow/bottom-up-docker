# Runs bud-init ($LAB_IMPL: starter or solution) as PID 1 of a new PID namespace and checks that it
# forwards signals, reaps orphans, passes exit codes through, and doesn't hang. Exit 0 = all pass.
export PATH=/usr/local/go/bin:$PATH GOTOOLCHAIN=local
IMPL=${LAB_IMPL:-starter}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
(cd "$IMPL/bud-init" && go build -o "$T/bud-init" .) || { echo "FAIL build"; exit 1; }
fails=0
check() { if [ "$2" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1 (want $2, got $3)"; fails=$((fails + 1)); fi; }

# Tests run under `bash -e`, and the exit codes being checked are non-zero on purpose, so every
# command whose status we check runs as `cmd && rc=0 || rc=$?`.
# run_pid1 <command...>: start bud-init as PID 1 in the background; sets U (job) and P1 (bud-init's host PID)
run_pid1() { timeout 10 unshare --pid --fork --mount-proc "$T/bud-init" -- "$@" & U=$!; sleep 0.5; P1=$(pgrep -f "^$T/bud-init" | head -1); }

# 1. SIGTERM sent to PID 1 reaches the command: its handler runs, records the signal and exits 5.
#    (A PID 1 that just dies on SIGTERM would take the command down with it, without the handler running.)
run_pid1 sh -c "trap 'echo TERM > $T/got; exit 5' TERM; sleep 30 & wait"
kill -TERM "$P1"; wait "$U" && rc=0 || rc=$?
check "SIGTERM is forwarded to the command" "5 TERM" "$rc $(cat "$T/got" 2>/dev/null || echo none)"

# 2. A command killed by a signal gives exit code 128 + the signal's number (SIGKILL is 9).
timeout 10 unshare --pid --fork --mount-proc "$T/bud-init" -- sh -c 'kill -KILL $$' && rc=0 || rc=$?
check "a command killed by signal n exits 128+n" 137 $rc

# 3. An orphan re-parented to PID 1 is reaped, so no zombie is left behind.
out=$(timeout 10 unshare --pid --fork --mount-proc "$T/bud-init" -- sh -c '(sleep 0.2 &); sleep 1; ps -o stat= | grep -c Z || true')
check "orphans are reaped (zombies left)" 0 "$out"

# 4. The command's exit code passes through.
timeout 10 unshare --pid --fork --mount-proc "$T/bud-init" -- sh -c 'exit 7' && rc=0 || rc=$?; check "exit code passes through" 7 $rc

# 5. A command that ignores SIGTERM keeps running; bud-init waits for it instead of hanging or quitting.
run_pid1 sh -c 'trap "" TERM; sleep 1; exit 3'; kill -TERM "$P1"; wait "$U" && rc=0 || rc=$?; check "doesn't quit early when the command ignores SIGTERM" 3 $rc

[ $fails -eq 0 ]
