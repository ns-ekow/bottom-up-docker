// bud-init: a minimal PID 1 for bud. Usage: bud-init -- command [args...]
//
// It starts the command, forwards termination-style signals to it, reaps every child that
// finishes (including orphans re-parented to it), and exits with the command's status.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

// Signals a PID 1 should pass on to the command. Everything else is left alone.
var forward = []os.Signal{syscall.SIGTERM, syscall.SIGINT, syscall.SIGHUP,
	syscall.SIGQUIT, syscall.SIGUSR1, syscall.SIGUSR2}

func main() {
	args := os.Args[1:]
	if len(args) > 0 && args[0] == "--" {
		args = args[1:]
	}
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "usage: bud-init -- command [args...]")
		os.Exit(2)
	}

	// Ask for signals before starting the command, so an early SIGCHLD can't be missed.
	// Installing handlers also matters for another reason: as PID 1, the kernel only delivers
	// signals we have a handler for.
	sigs := make(chan os.Signal, 64)
	signal.Notify(sigs, append([]os.Signal{syscall.SIGCHLD}, forward...)...)

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, "bud-init:", err)
		os.Exit(127)
	}
	main := cmd.Process.Pid

	for sig := range sigs {
		s := sig.(syscall.Signal)
		if s != syscall.SIGCHLD {
			syscall.Kill(main, s) // forward; the command decides what to do with it
			continue
		}
		// Several children can finish while one SIGCHLD is pending, so loop until none are left.
		for {
			var ws syscall.WaitStatus
			pid, err := syscall.Wait4(-1, &ws, syscall.WNOHANG, nil)
			if pid <= 0 || err != nil {
				break
			}
			if pid == main {
				os.Exit(exitCode(ws))
			}
		}
	}
}

// exitCode turns a wait status into a shell-style exit code: the code itself, or 128+n for signal n.
func exitCode(ws syscall.WaitStatus) int {
	if ws.Signaled() {
		return 128 + int(ws.Signal())
	}
	return ws.ExitStatus()
}
