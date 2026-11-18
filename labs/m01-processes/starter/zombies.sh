# List every zombie process on the system, using only /proc (no ps).
# For each zombie print one line:  <zombie pid> <parent pid> <parent command>
# Hint: /proc/<pid>/status has "State:", "PPid:"; /proc/<pid>/comm has the command name.
# Check your work with: tools/lab test m01
