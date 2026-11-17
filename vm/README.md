# Lab VM

All experiments run here, never on your host. The VM is disposable: break it, then rebuild it.

| File | What it does |
|---|---|
| `bud.yaml` | Lima definition: Ubuntu 26.04 LTS (image pinned by sha256), 4 CPUs, 3 GiB RAM, 20 GiB sparse disk, only this repo mounted at `/course` |
| `versions.env` | Every component version + sha256. The single source of truth for the VM. |
| `provision.sh` | Installs the pinned stack (Go, Docker, containerd, runc, BuildKit, buildx, delve, tracing/network tools). Runs as root inside the VM; idempotent. |
| `verify` | Checks every component against `versions.env`; prints kernel, cgroup and OS facts |
| `reset` | Host-side: delete, recreate, provision, verify. One command back to a clean state. |

## Host prerequisites

- Linux x86_64 with KVM (`/dev/kvm` readable/writable by you)
- `sudo apt install -y qemu-system-x86 qemu-utils ovmf jq sqlite3`
- Lima 2.3.0 in `~/.local` (release tarball, checksum-verified)

## Use

```bash
vm/reset                     # build or rebuild from scratch (~10 min first time)
limactl shell bud            # open a shell in the VM; the repo is at /course
limactl stop bud             # stop it; limactl start bud brings it back
```

## Rules

- Destructive experiments go in VM-local paths (`/var/lib/bud`, `/tmp`), **never** under `/course`, which is your real repo, mounted writable.
- If something is wedged, `vm/reset`. Never fix the VM by hand in a way the scripts don't reproduce.
