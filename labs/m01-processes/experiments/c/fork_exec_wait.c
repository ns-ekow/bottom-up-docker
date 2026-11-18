// fork a child; the child replaces itself (exec) with a small shell command that checks which files
// it still has open; the parent waits for it. Before forking, the parent opens one file normally
// (fd 3) and one close-on-exec (moved to fd 7), which exec closes automatically.
#include <fcntl.h>
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void) {
    int kept = open("/etc/hostname", O_RDONLY);                         // lowest free number: 3
    int tmp = open("/etc/hostname", O_RDONLY);
    int closed_on_exec = fcntl(tmp, F_DUPFD_CLOEXEC, 7);                // a copy at fd 7, close-on-exec
    close(tmp);
    printf("parent: pid %d, fd %d open normally, fd %d open close-on-exec\n", getpid(), kept, closed_on_exec);
    fflush(stdout);

    pid_t child = fork();
    if (child == 0) {
        printf("child: pid %d, parent %d, about to exec\n", getpid(), getppid());
        fflush(stdout);
        execl("/bin/sh", "sh", "-c",
              "for fd in 3 7; do [ -e /proc/self/fd/$fd ] && echo \"after exec: fd $fd open\" "
              "|| echo \"after exec: fd $fd closed\"; done", (char *)NULL);
        _exit(127);                                                      // only reached if exec failed
    }
    int status;
    pid_t done = waitpid(child, &status, 0);
    printf("parent: wait returned pid %d, exit status %d\n", done, WEXITSTATUS(status));
    printf("parent: wait returned the pid fork gave the parent: %s\n", done == child ? "yes" : "no");
    return 0;
}
