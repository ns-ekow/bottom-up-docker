# Citations and verification

## Grammar (same everywhere: `<Claim src>`, `<Walkthrough src>`, glossary `sources`)

| Kind | Form | Example |
|---|---|---|
| corpus passage | `<source>:<file>#<anchor>` | `man:pivot_root.2#notes`, `oci-runtime:config.md#mounts` |
| pinned code | `<repo>@<commit-prefix>:<path>#L<a>-L<b>` | `runc@46365c6:libcontainer/rootfs_linux.go#L1160-L1210` |
| experiment | `exp:m<id>/<name>` | `exp:m03/pivot-root` |

Several sources: `src="a; b"`. Find corpus anchors with `tools/ask`; read one in full with
`tools/ask --show <cid>`. The commit prefix must match `pins.lock` (check-links enforces it).

## Tiers

| Tier | Examples | Rule |
|---|---|---|
| T1 | specs, man pages, kernel docs, official project docs | can stand alone |
| code / experiment | pinned source lines, a lab experiment | can stand alone; strongest evidence for behaviour |
| T2 | Poulton's book, LWN | explanation and history; a behaviour claim also needs T1, code or an experiment |
| T3 | dated articles | context only; never the only source |

## Where a citation goes

On the sentence (or clause) it supports, at the end: `... the old root <Claim src="..." />.`
One claim per fact. If a sentence makes two separate claims from two sources, either split the
sentence or put a Claim after each clause; the checker judges the text between the previous Claim
and this one.

Not everything is a claim: transitions, instructions ("Run this:"), and the module's own question
need no citation. Anything a reader could get wrong about the world does.

## How the adversarial check fails you, and the fix for each

The checker sees only your sentence and the cited passages, and tries to refute it. From building
the glossary, nearly every failure was one of these:

| Pattern | Example | Fix |
|---|---|---|
| **Plain-language extra** the source doesn't state | "…which is how each container gets its own hostname" cited to `uts_namespaces(7)` (never mentions containers) | Cite a source that makes the link (Docker docs, OCI spec, code), or cut the clause |
| **Dropped qualifier** | "doesn't affect the rest of the system" vs the man page's "by default (but see shared subtrees)" | Keep the qualifier: "by default, …" |
| **Scope widened** | "containers on the same host can reach each other" vs docs' "on the same bridge network" | Use the source's exact scope |
| **Absolute words** | "always", "every", "only", "never", "the only way" | Drop them unless the source says them |
| **Examples not in the source** | naming SIGTERM/SIGKILL, `/bin`, Docker Hub | Add a source for the example, or remove it |
| **Causal "because/so"** the source doesn't state | "runc uses pivot_root *so the container can't reach host files*" | State the action; cite the reason separately or drop it |
| **Contradiction with the spec's precise definition** | "a bundle is a directory" vs spec: "that directory itself is not part of the bundle" | Use the spec's definition |
| **Docs don't say it, code does** | that Docker's overlay network creates VXLAN devices | Cite the pinned code lines |

Never "win" against a verdict by rewording until it passes while the meaning stays the same. If you
believe the claim is true and no source states it, write an experiment that shows it, or find the
code that does it.

## Run order

1. `tools/check-links <file>`: every reference resolves (instant, free).
2. `tools/check-claims <file>`: tier rules (free).
3. `tools/check-claims --adversarial <file>`: skeptical check; cached by content, so re-runs
   only pay for changed claims.
4. Before setting `status = "review"`: `tools/check-claims --adversarial --fresh <file>`.
   Verdicts on borderline wording vary between runs (the same claim can pass once and be flagged
   the next time), so a fresh run is what stops a lucky pass from sticking. Treat any new PARTIAL
   as real.

Cost: one model call per new or changed claim (a few cents). Don't avoid the check to save cost.
