# List every zombie process on the system, using only /proc (no ps).
# Prints one line per zombie: <zombie pid> <parent pid> <parent command>
for status in /proc/[0-9]*/status; do
  read -r state ppid < <(awk '/^State:/ {s = $2} /^PPid:/ {p = $2} END {print s, p}' "$status" 2>/dev/null) || continue
  [ "$state" = Z ] || continue
  pid=${status#/proc/}; pid=${pid%/status}
  echo "$pid $ppid $(cat /proc/"$ppid"/comm 2>/dev/null)"
done
