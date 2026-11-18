# /proc/self is a link to the /proc directory of whichever process reads it, so two different
# commands see two different PIDs. A file the shell opens on fd 3 is inherited by its children.
a=$(readlink /proc/self); b=$(readlink /proc/self)
echo "shell pid: $$; readlink /proc/self saw $a, then $b"
[ "$a" != "$b" ] && echo "each command saw its own PID: yes"
ppid=$(awk '/^PPid:/ {print $2}' /proc/self/status)
echo "awk's parent (PPid in /proc/self/status) is the shell: $([ "$ppid" = $$ ] && echo yes || echo no)"
exec 3</etc/hostname
ls -l /proc/self/fd | awk '$9 ~ /^[0-3]$/ {print "ls has fd", $9, $10, $11}'
