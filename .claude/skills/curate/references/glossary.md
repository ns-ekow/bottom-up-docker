# Glossary

`glossary.toml` is the plain-language dictionary for the whole course. The site links the first use
of each term on every page to its entry, with `short` shown on hover. Its header documents the
fields; `tools/check-glossary` enforces the structural rules.

## When a term needs an entry

A word needs an entry when the target reader (a programmer with no OS or networking background)
would have to look it up, **and** it's used on more than one page or is central to a module. A
one-off term can be explained inline instead. `scripts/jargon-scan <file>` lists candidates; you
judge them.

## Writing an entry

- **`short`**: one sentence, 30 words max, that the target reader understands without other help.
  Say what it *is* and what it's *for*. Every other technical word in it must itself be a glossary
  term (or plain English).
- **`body`** (optional): one to three sentences: an everyday comparison, or how it shows up in
  Docker. Same rules: everything stated must be supported by the sources.
- **`sources`**: at least one T1, code or experiment source. Prefer the most primary: the man page
  over the docs, the spec over the book, the code when the docs don't say it.
- **`see`**: closely related term ids.
- **`group`**: the topic group, from `groups` at the top of the file. The file stays **grouped by
  topic** (not alphabetical); put the entry in its group next to related terms, and say in your
  report which group you chose and why when it isn't obvious.
- **`id`**: lowercase-with-dashes, used as the page anchor.

## Aliases: the part that silently goes wrong

Aliases are the word forms that link to the entry, matched as whole words; ALL-CAPS aliases match
case-sensitively, others ignore case. The first match on a page gets linked, so a too-broad alias
mislinks text that means something else.

Before adding an alias, check where it would match:

```
.claude/skills/curate/scripts/jargon-scan --alias "exec"
```

It prints every occurrence in the lessons, guides and curriculum with context. If any occurrence
means something else ("docker exec" is a Docker command, not the execve system call), narrow the
alias (`execve`, `exec system call`) instead.

Include the forms readers will meet: singular and plural, the common short form, the `name(2)` form
for system calls. No alias may belong to two terms.

## Verify

```
tools/check-glossary
tools/check-claims --adversarial --fresh glossary.toml
```

Definitions fail the adversarial check for the same reasons lesson claims do (see
`citations.md`): plain-language extras, dropped qualifiers, widened scope, absolute words. Narrow
or re-source; don't argue.
