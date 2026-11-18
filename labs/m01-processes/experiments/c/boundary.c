// Opens a file, writes one line, closes it. Every step is a request to the kernel.
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char **argv) {
    int fd = open(argv[1], O_WRONLY | O_CREAT | O_TRUNC, 0644);
    write(fd, "hello\n", 6);
    close(fd);
    return 0;
}
