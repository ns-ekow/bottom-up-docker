# bottom-up-docker

A course that takes programmers from "I can write code and use a shell" to understanding Docker
deeply enough to build on it, contribute to it, or reinvent it. Each layer (namespaces,
cgroups, overlayfs, the OCI runtime, images, networking, the engine, builds, security) is first
observed on a real kernel, then built in Go, then read and traced in the production source,
pinned to a frozen version of the stack.

Every factual claim is cited to an authoritative source, and every behavioral claim is backed by
a runnable experiment.

## Quick start (Linux x86_64 with hardware virtualization)

```bash
git clone <this repo> && cd bottom-up-docker
./setup --check      # see what's missing; changes nothing
./setup              # fixes what it can (asks before every sudo), builds everything (~15 min)
cd site && npm run dev   # read the course at http://localhost:4321
```

`./setup` checks virtualization support, loads KVM and grants access if needed, installs QEMU and a
few host tools, puts Lima in `~/.local`, fetches the pinned source, builds the lab VM, builds the
citation corpus, installs the site, and finishes with a self-test. It is safe to re-run.
Prerequisites it won't install for you: Node >= 22.23.4 (use nvm) and Python >= 3.11.
Supply your own copies of the course PDFs in `corpus/private/books/` (names in `corpus/manifest.toml`).

- Plan and syllabus: [`PLAN.md`](PLAN.md)
- Frozen versions: [`pins.lock`](pins.lock)
