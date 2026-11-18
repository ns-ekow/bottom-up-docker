# Course tooling

All local, stdlib Python + bash. Run from the repo root on the **host**.

## Setup (once per machine)

```bash
tools/fetch-src        # pinned upstream source -> src/          (~730 MB)
vm/reset               # lab VM with the pinned stack            (~10 min)
tools/fetch-corpus     # accuracy corpus -> corpus/cache/        (needs the VM running, for man pages,
                       #   and your own copies of the PDFs in corpus/private/books/)
tools/index            # search index (tools/ask also rebuilds it when stale)
```

## Retrieval

```bash
tools/ask "how are deleted lower-layer files hidden"   # ranked, citable passages
tools/ask --tier T1 -n 3 "pivot_root put_old"          # authoritative sources only
tools/ask --show man:pivot_root.2#notes                # one passage in full
tools/ask --miss "question that found nothing"         # log a retrieval miss -> corpus/misses.md
```

For code, search `src/` directly (`rg`, `gopls`). Exact search beats ranked search for identifiers.

## Citations (in lessons)

```mdx
Text of the claim <Claim src="man:setns.2#description~2" />.
Several sources <Claim src="oci-runtime:config.md#mounts; runc@46365c6:libcontainer/rootfs_linux.go#L40-L80" />.
Proven by running it <Claim src="exp:m03/pivot-root" />.
```

| Kind | Form | Resolves to |
|---|---|---|
| corpus | `<source>:<file>#<anchor>` | a passage in the index (find with `tools/ask`) |
| code | `<repo>@<commit-prefix>:<path>#L<a>-L<b>` | lines at the pinned commit; the prefix must match `pins.lock` |
| experiment | `exp:<module>/<name>` | `labs/<module>-*/experiments/<name>.sh` (+ `.expected`) |

## Verification

```bash
tools/check-curriculum                  # lessons match curriculum.toml; reading paths exist at pins
tools/check-glossary                    # glossary.toml rules: unique terms/aliases, short plain definitions, T1 sources
tools/check-links                       # every citation resolves (fast, offline)
tools/check-claims                      # + tier rules: T3-only fails, T2-only warns
tools/check-claims --adversarial        # + LLM tries to refute each claim from ONLY its passages
tools/lab exp m03/pivot-root            # run one experiment in the VM, compare to .expected
tools/lab test m03                      # run a module's tests in the VM
tools/lab all                           # every experiment, and exercise tests against the starters
tools/lab all --solution                # the same, with tests against the reference solutions
```

`tools/tests/claims-fixture.mdx` has one deliberate case per verdict; run the checkers against it
after changing them. The adversarial check calls the local `claude` CLI with all tools disabled,
from an empty directory. Each new or changed claim costs one model call (a few cents); verdicts are cached in
`corpus/cache/verdicts.json` by content hash.

| File | Purpose |
|---|---|
| `fetch-src` | Clone pinned repos (shallow) + sparse Linux into `src/` |
| `fetch-corpus` | Build normalized, chunked corpus from `corpus/manifest.toml`; record hashes in `manifest.lock` |
| `index` | SQLite FTS5 index over the chunks |
| `ask` | Search CLI |
| `budlib.py` | Shared: pins, citation grammar, resolution |
| `check-links` | Structural citation check |
| `check-claims` | Tier rules + adversarial support check |
| `lab` | Run experiments and tests inside the VM |
| `check-curriculum` | Enforce `curriculum.toml` against pins, corpus and lessons |
| `check-glossary` | Enforce `glossary.toml` rules (definitions are also checked as claims by `check-claims`) |
| `publish-site` | Check, build locally and publish the site to the `gh-pages` branch (GitHub Pages) |
| `graphs/godeps` | Package-import graph of a pinned Go repo (`go list` + Graphviz, in the VM; byte-identical across runs) |
| `site-data` | Resolves every reference in the lessons for the site build (same resolver as the checkers) |
