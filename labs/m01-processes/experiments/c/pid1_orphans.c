// Runs as PID 1 in a new PID namespace. It starts one child that starts a grandchild and exits,
// leaving the grandchild orphaned. PID 1 waits only for its own child, so the orphan it adopts
// becomes a zombie when it ends. Only when PID 1 waits for any child does the zombie go away.
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

static void show(const char *when) {
    printf("-- %s\n", when);
    fflush(stdout);
    system("ps -o pid,ppid,stat,comm --no-headers");
}

int main(void) {
    printf("pid1: my pid is %d\n", getpid());
    pid_t child = fork();
    if (child == 0) {
        if (fork() == 0) { sleep(1); _exit(0); }   // grandchild: lives 1s, then exits
        _exit(0);                                  // child exits at once, orphaning the grandchild
    }
    waitpid(child, NULL, 0);                       // wait for our own child only
    usleep(200 * 1000);
    show("orphan adopted (its parent is now 1)");
    sleep(2);
    show("orphan has exited, but PID 1 has not waited for it");
    int collected = 0;
    while (waitpid(-1, NULL, WNOHANG) > 0) collected++;   // collect any finished child
    printf("PID 1 collected %d finished child(ren)\n", collected);
    show("after PID 1 waited for any child");
    return 0;
}
