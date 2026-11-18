# Labs: experiments and exercises

## Layout

```
labs/m<id>-<slug>/
├── README.md              what the lab covers
├── experiments/
│   ├── <name>.sh          runs as root in the VM via `tools/lab exp m<id>/<name>`
│   └── <name>.expected    regex per line, matched in order against the output
├── starter/               code the learner starts from (may be empty)
├── solution/              reference solution (public)
└── tests/                 *.sh (exit 0 = pass) and/or Go tests (go.mod in the lab dir)
```

`m01-processes` is a complete example (experiments, starter, solution, tests); copy its shape.
`m00-harness` is an internal check used by `./setup`, not a course lab.

## Experiments

- **VM only, VM-local paths only.** Scripts run as root inside the lab VM with
  `bash -euo pipefail`, from their own directory. Write under `/var/lib/bud` or `/tmp`, never
  `/course` (that's the real repo, mounted from the host). Clean up what you create, or create
  inside a fresh temp dir, so a re-run starts clean.
- **Check the guard rail before the dangerous part.** If an experiment does something that could
  hurt the VM without a limit (a fork bomb, filling memory or disk), read the limit back and refuse
  to continue if it isn't set: `[ "$(cat "$CG/pids.max")" = 20 ] || { echo "limit not set"; exit 1; }`.
  Give anything you create (cgroups, namespaces, interfaces) a name unique to the run, so parallel
  runs don't collide.
- **Stock tools first.** Experiments observe the kernel with `unshare`, `nsenter`, `ip`, `nft`,
  `mount`, `/proc`, `/sys/fs/cgroup`, `strace`. Docker itself only when the experiment is about
  Docker's behaviour.
- **Run, then write `.expected`.** Write the script, run `tools/lab exp m<id>/<name>`, read the
  real output, then write `.expected` from it. Keep only the lines that prove the point, as anchored
  regexes (`^inside: pid=1$`). Loosen what legitimately varies (PIDs, addresses, timings) with
  `[0-9]+` etc.; never loosen the thing being proven.
- **When the output surprises you, the experiment is right.** Fix your understanding and the prose,
  not the regex. (Counting processes with `$(ps | wc -l)` shows 4, not 2: the subshell and `wc`
  count too. That kind of surprise is the lesson.)
- A one-line comment at the top says what the experiment shows, in plain language. No history.

## Exercises

- **Tests define done.** Write them first, from the exercise text.
- **`$LAB_IMPL`** tells tests which code to check: `starter` (default) or `solution`. Shell tests
  read it from the environment; Go tests read `os.Getenv("LAB_IMPL")`.
- **Prove the tests discriminate:**
  - `tools/lab test m<id>` → must **fail** (starter doesn't do it yet)
  - `tools/lab test m<id> --solution` → must **pass**
- Solutions are public. Write them as you'd want a reader to learn from them: small, commented
  where the reasoning isn't obvious, no cleverness.
- **Exercises that patch real code** (runc, containerd, moby): the patch lives in `solution/` as a
  `.patch` file; the test builds the patched binary in the VM from a scratch copy of `src/<repo>`
  (never modify `src/` itself) and checks the observable effect.
- **bud exercises** build the module's `build` item from `curriculum.toml` in
  `projects/bud/`; tests check the behaviour, not the implementation.
