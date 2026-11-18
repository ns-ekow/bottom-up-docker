# PID 1 of a namespace only receives signals it has a handler for. SIGTERM, from inside or outside
# the namespace, is ignored by a PID 1 with no handler; a handler makes it react. SIGKILL from the
# parent namespace always works, and when PID 1 dies every other process in the namespace dies too.
start() { unshare --pid --fork --mount-proc "$@" & U=$!; disown "$U"; sleep 0.3; P1=$(pgrep -P "$U" | head -1); }
alive() { kill -0 "$1" 2>/dev/null && echo alive || echo gone; }

start sleep 30
nsenter -t "$P1" -p -m kill -TERM 1; sleep 0.3; echo "sleep as PID 1, SIGTERM from inside: $(alive "$P1")"
kill -TERM "$P1"; sleep 0.3;                  echo "sleep as PID 1, SIGTERM from outside: $(alive "$P1")"
kill -KILL "$P1"; sleep 0.3;                  echo "sleep as PID 1, SIGKILL from outside: $(alive "$P1")"

start sh -c 'trap "echo PID 1 handled SIGTERM; exit 0" TERM; sleep 30 & wait'
nsenter -t "$P1" -p -m kill -TERM 1; sleep 0.3; echo "sh with a handler as PID 1, after SIGTERM: $(alive "$P1")"

start sh -c 'sleep 100 & sleep 100'
C=$(pgrep -P "$P1" | head -1)
kill -KILL "$P1"; sleep 0.3; echo "another process in the namespace, after PID 1 was killed: $(alive "$C")"
