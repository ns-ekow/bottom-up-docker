# Lesson format

## File, title, header

- File: `site/src/content/docs/modules/<id>-<slug>.mdx`, where `<id>` is the curriculum id
  (`03`) and `<slug>` is short kebab-case (`namespaces-i`).
- Front matter `title` must be exactly `"<id> · <curriculum title>"`.
- First thing in the body: `<ModuleHeader id="<id>" />`. It renders the objectives and build from
  `curriculum.toml`, so a lesson can't drift from its promise.
- `## Question` must state the curriculum's question **exactly**, as its first paragraph.
  `tools/check-curriculum` enforces title, header and question.

## The seven sections (all required once status is `review`)

| Section | Purpose | Typical content |
|---|---|---|
| `## Question` | The one question the module answers | The curriculum question, verbatim, then one or two sentences on why it matters |
| `## Concept` | The idea, briefly | Short paragraphs, every fact cited; a diagram if it helps |
| `## Experiment` | See it on a real kernel | One or more `<Experiment>`s, each followed by a cited sentence on what it showed |
| `## Build` | Implement it in Go | What to build for `bud`, the interface, the tests that check it |
| `## Read` | The production code | `<Walkthrough>`s over the curriculum's reading paths, with `<Note>`s; a `<Graph>` if useful |
| `## Trace` | Watch that code run | Exact commands (`strace -f`, `bpftrace`, `dlv`), what to look for, an example of the output |
| `## Exercise` | Graded practice | Tasks, tests, how to run them; at least one patches real code, one extends `bud` |

Close the module with a short **toy vs production** table (in Read or after Exercise): what the
real code handles that the reader's toy didn't, and why.

## Components

```mdx
import { ModuleHeader, Claim, Walkthrough, Note, Experiment, Graph } from '@components';

Sentence that states a fact <Claim src="man:setns.2#description" />.

<Experiment id="m03/pivot-root" title="A container from nothing but unshare and pivot_root" />

<Walkthrough src="runc@46365c6:libcontainer/rootfs_linux.go#L1160-L1210" title="pivotRoot" mark="1180">
  <Note lines="1176-1178">
    Changes into the new root first, so `pivot_root(".", ".")` acts on it <Claim src="runc@46365c6:libcontainer/rootfs_linux.go#L1176-L1182" />.
  </Note>
</Walkthrough>

<Graph svg="graphs/<name>.svg" caption="…" from="tools/graphs/godeps <repo> <package-pattern> <name>" />
```

- **Walkthrough** ranges: aim for 20–60 lines each; a module's total reading is 200–600 lines.
  Notes use **file** line numbers; each note's claims cite the exact lines.
- **Graph**: only deterministic graphs (`tools/graphs/`), never hand-drawn or LLM-generated maps.
  Look at the rendered SVG before using it; byte-identical output can still be broken.
- Links between pages are relative (`../03-namespaces-i/`), never root-absolute (`/modules/…`),
  because the published site lives under a sub-path.

## Status

`planned` → `drafting` (you, when the lesson file is created) → `review` (you, when every gate
passes) → `published` (a human, after co-learner review).
