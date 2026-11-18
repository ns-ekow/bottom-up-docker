---
name: curate
description: Curate bottom-up-docker course content end to end - research a module from the citation corpus and pinned source, outline it, write it in plain language with every claim cited, catch and define jargon in the glossary, build experiments that are run in the lab VM before their expected output is written, write graded exercises with reference solutions, and run every verification gate until it passes. Use this whenever working on the course's content in this repo - drafting or revising a module or lesson, adding or fixing an experiment, exercise, walkthrough, citation or glossary term, sweeping a page for jargon or unclear wording, or checking whether content is ready for review - even if the request doesn't say "curate".
---

# Curate course content

This repo is a course that takes a programmer from "I can code and use a shell" to understanding
Docker deeply enough to rebuild it. Its promise to the reader has three parts, and this skill exists
to keep all three on every page:

1. **Plain.** Written for a programmer who has never studied operating systems or networking.
   Every technical term is either defined in the glossary (and auto-linked) or explained in the
   sentence where it first appears.
2. **True.** Every factual sentence cites a source, and the sources are tiered: specs, man pages,
   kernel docs, official docs and pinned source code can stand alone; books and articles can't. A
   claim about behaviour is backed by an experiment that actually ran.
3. **Hands-on.** Each module observes the thing on a real kernel, builds it in Go, then reads and
   traces the production code that does the same job.

The tools already exist in the repo. This skill is the workflow that ties them together, plus the
judgement the tools can't supply.

## Where things are

| What | Where |
|---|---|
| Curriculum (single source of truth: titles, questions, objectives, reading paths, status) | `curriculum.toml` |
| Glossary (plain definitions, aliases, sources, grouped by topic) | `glossary.toml` |
| Lessons | `site/src/content/docs/modules/<id>-<slug>.mdx` |
| Labs: experiments, exercises, tests, solutions | `labs/m<id>-<slug>/` |
| Pinned upstream source (read-only) | `src/<repo>/`, commits in `pins.lock` |
| Citation corpus manifest | `corpus/manifest.toml` |
| Search the corpus | `tools/ask "question"`, `tools/ask --show <cid>` |
| Run labs in the VM | `tools/lab exp m05/name`, `tools/lab test m05 [--solution]` |
| All verification gates | `.claude/skills/curate/scripts/verify` |

Read `tools/README.md` once if you haven't; it documents the citation grammar and every tool.

## Pick the job

| The request | Do this |
|---|---|
| Draft, write or rework a **module** | Module workflow below. Outline first, then stop for approval. |
| Add or fix an **experiment** | Experiment workflow; read `references/labs.md` |
| Add or fix an **exercise** | Exercise workflow; read `references/labs.md` |
| Add, fix or check **glossary** terms | Glossary workflow; read `references/glossary.md` |
| "Is this page clear / are terms defined / is it ready?" | Audit workflow |

Whatever the job, finish with the **report** (last section) so the human sees what changed, what
was verified and what still needs their judgement.

## Module workflow

### 1. Research (before writing anything)

- Read the module's entry in `curriculum.toml`. Its question, objectives, reading paths and
  sources are the contract; the lesson must deliver exactly those.
- Search the corpus for each objective: `tools/ask -n 5 --tier T1 "..."`. Read the passages you
  will rely on in full (`tools/ask --show <cid>`), because the snippet can hide the qualifier that
  makes a sentence false.
- Open every reading path in `src/` and pick the 200–600 lines that answer the module's question.
  Record exact line ranges at the pinned commit.
- List the experiments: what will the reader run, and what must it show?
- Run `scripts/jargon-scan` mentally over your planned wording: which terms will the reader meet
  for the first time? Which are already in `glossary.toml`?
- If a needed source is missing from the corpus, find it, but propose adding it in the outline
  rather than adding it silently: sources decide what counts as true.

### 2. Outline, then stop

Write the outline using `assets/outline-template.md` and present it. Then **stop and wait for the
human's approval**. This is a learning project: the human is learning this material as it is
written, and the outline is where they steer. Don't write the lesson in the same turn unless they
have already approved an outline.

### 3. Write

Start from `assets/lesson-template.mdx`. Set the module's `status` to `drafting` in
`curriculum.toml` when you create the lesson file. Follow `references/lesson-format.md` for the
seven sections and the components, `references/plain-language.md` for wording, and
`references/citations.md` for claims. Write experiments before the prose that describes their
results (see the experiment workflow), so the prose reports what actually happened.

### 4. Verify until clean

Run `scripts/verify <id>` (fast gates), fix, repeat. Then run `scripts/verify <id> --adversarial`,
which re-checks every claim from scratch (`--fresh`). For every PARTIAL or worse, **narrow the
sentence to what the source says, or find a source for the extra detail**, never argue with the
verdict. `references/citations.md` lists the patterns that cause most failures.

When every gate passes, set `status = "review"`. That's as far as this skill goes: a co-learner
reviews against the checklist, and only a human sets `published`.

## Experiment workflow

1. Write the script in `labs/m<id>-<slug>/experiments/<name>.sh`. Scripts run as root in the VM,
   so they must only touch VM-local paths (`/var/lib/bud`, `/tmp`), never `/course`, which is the
   human's real repo.
2. **Run it before writing the expected output**: `tools/lab exp m<id>/<name>`. Look at what it
   printed and why. Then write `<name>.expected` (one regex per line, matched in order) from the
   real output, keeping only the lines that prove the point. Expected output written from belief
   is how wrong lessons get published.
3. Run it again with the `.expected` in place; it must pass.
4. Embed it in the lesson with `<Experiment id="m<id>/<name>" />` and cite it
   (`<Claim src="exp:m<id>/<name>" />`) from the sentence that states the result.

## Exercise workflow

1. Write the task in the lesson's Exercise section: what to build, what "done" means, and which
   tests check it.
2. Put starter code in `labs/m<id>-<slug>/starter/`, tests in `tests/`, and the reference
   solution in `solution/` (solutions are public in this repo). Tests find the code under test
   through `$LAB_IMPL` (`starter` or `solution`).
3. Prove the tests are meaningful: `tools/lab test m<id>` must **fail** on the starter, and
   `tools/lab test m<id> --solution` must **pass**. A test that passes on the starter tests nothing.
4. At least one exercise per module changes the real code (patch runc, containerd or moby at the
   pin, rebuild, observe), and one extends `bud` with the module's `build` from the curriculum.

## Glossary workflow

Read `references/glossary.md` first. In short: one plain sentence (30 words max) a reader with no
OS background understands; every other technical word in it is itself a glossary term; at least
one T1, code or experiment source; place it in the right topic group and say why; check every
alias for wrong matches with `scripts/jargon-scan --alias "<alias>"` (the bare word `exec` would
have linked "docker exec" to the execve system call). Then `tools/check-glossary` and
`tools/check-claims --adversarial --fresh glossary.toml`.

## Audit workflow

Run `scripts/verify` on the page or module, plus `scripts/jargon-scan` and `scripts/readability`
on the file. Read the page as the target reader would. Report findings ranked by how much they'd
confuse or mislead a reader; fix only what the human asks you to.

## Rules that protect the project

- **Never push, publish, or create anything public.** No `git push`, no `tools/publish-site`, no
  repo or release creation. Say what's ready and let the human do it. Commit locally only when asked.
- **Never set `status = "published"`**; that's a human review decision.
- **No personal or machine-specific details** in anything you write: no names, home paths, host
  RAM, "on this machine", or session narration ("an earlier version did…"). Write for a stranger
  on a different machine, a year from now.
- **Don't edit pinned source** in `src/` except inside an exercise that patches it on purpose,
  and never commit `src/`.
- **Don't add corpus sources silently.** Propose them; the human approves what counts as truth.

## The report

End every job with this, in plain language:

```
## What I did
<files created/changed, one line each>

## Verified
<each gate and its result, e.g. "check-claims --adversarial --fresh: 23/23 supported">

## Needs your judgement
<anything flagged and left, choices you made (e.g. glossary group), and open questions>

## Next
<the one or two most useful next steps>
```
