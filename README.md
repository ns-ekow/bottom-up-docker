# bottom-up-docker

A course that takes programmers from "I can write code and use a shell" to understanding Docker
deeply enough to build on it, contribute to it, or reinvent it. Each layer (namespaces,
cgroups, overlayfs, the OCI runtime, images, networking, the engine, builds, security) is first
observed on a real kernel, then built in Go, then read and traced in the production source,
pinned to a frozen version of the stack.

Every factual claim is cited to an authoritative source, and every behavioral claim is backed by
a runnable experiment.

- Plan and syllabus: [`PLAN.md`](PLAN.md)
- Frozen versions: [`pins.lock`](pins.lock)
