// bud-init: a minimal PID 1 for bud. Usage: bud-init -- command [args...]
//
// This starter runs the command and waits for it, and nothing else. Make it a proper PID 1:
//  1. Forward SIGTERM, SIGINT, SIGHUP, SIGQUIT, SIGUSR1 and SIGUSR2 to the command.
//  2. On SIGCHLD, collect (reap) every finished child, not just the command: orphans in the
//     namespace are re-parented to PID 1, and stay zombies until PID 1 waits for them.
//  3. When the command finishes, exit with its status: its exit code, or 128+n if signal n killed it.
// Check your work with: tools/lab test m01
package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	args := os.Args[1:]
	if len(args) > 0 && args[0] == "--" {
		args = args[1:]
	}
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "usage: bud-init -- command [args...]")
		os.Exit(2)
	}

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := cmd.Start(); err != nil {
		fmt.Fprintln(os.Stderr, "bud-init:", err)
		os.Exit(127)
	}

	// TODO: forward signals to the command (1), reap every child (2).
	cmd.Wait()

	// TODO: exit with the command's status (3).
	os.Exit(0)
}
