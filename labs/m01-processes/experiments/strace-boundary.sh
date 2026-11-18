# Every action a program takes on a file is a system call: strace shows openat, write, close and
# exit_group, each with the value the kernel returned. The file descriptor openat returns is the
# number write and close then use.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
gcc -O0 -o "$T/boundary" c/boundary.c
strace -o "$T/trace" -e trace=openat,write,close,exit_group "$T/boundary" "$T/out.txt"
# Skip the loader's own file openings; start at the program's openat of out.txt.
sed -n '/out\.txt/,$p' "$T/trace" | sed "s#$T#TMP#"
