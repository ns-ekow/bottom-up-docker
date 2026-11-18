# Plain language

## The reader

A programmer who can write code in some language and use a shell, but has **never studied operating
systems or networking**. They know what a file, a function and a command are. They do not know
what a namespace, a syscall, NAT or a mount point is, and every unexplained term costs them.

Write as if explaining to that person sitting next to you. They're smart; they're just new to this.

## Rules

1. **Define before you use.** The first time a technical term appears on a page, it must be either
   a glossary term (it will be auto-linked with a hover definition) or explained in that same
   sentence. If it's neither, add it to the glossary or explain it. `scripts/jargon-scan` lists
   candidates; you decide which ones a reader would trip on.
2. **One idea per sentence.** Aim for 15–20 words on average; split anything over 30.
   `scripts/readability` flags long sentences.
3. **Concrete before abstract.** Show the command, the output, or the file first; name the concept
   after the reader has seen it. "Run `unshare --pid --fork sh`. Inside, `echo $$` prints 1. That
   shell is in a new *PID namespace*…"
4. **Say what it is, then what it's for.** "A veth pair is two virtual network interfaces joined
   like a cable. Docker uses one to connect each container to the host."
5. **Prefer everyday words.** "use" not "utilize", "start" not "instantiate", "about" not
   "approximately". Keep technical terms only when they're the thing being taught.
6. **No hedging filler, no hype.** Cut "basically", "simply", "just", "of course", "it's worth
   noting", "powerful", "seamless". "Simply" is especially harmful: if the reader finds it hard,
   it tells them they're slow.
7. **Analogies are welcome, but mark them as analogies** and don't let them carry a factual claim
   the source doesn't make. "Like the two ends of a cable" is fine; "like a VM" is misleading.
8. **Code identifiers in backticks** (`pivot_root`, `CLONE_NEWPID`, `/proc/self/ns`). The glossary
   links a backticked span only if the whole span is a term.

## Before and after

> **Before:** The runtime leverages the `CLONE_NEWNS` flag to instantiate a new mount namespace,
> thereby isolating the container's view of the VFS hierarchy.
>
> **After:** runc asks the kernel for a new mount namespace by passing the `CLONE_NEWNS` flag. From
> then on, mounts made inside the container don't show up on the host, and the other way round.

Why: "leverages", "instantiate", "thereby" add nothing; "VFS hierarchy" is two undefined terms; the
after version says what changes for the reader.

> **Before:** Overlayfs implements CoW semantics via copy-up on first write.
>
> **After:** When a container first writes to a file that came from the image, overlayfs copies the
> file into the container's own layer and changes the copy. The image's file is never modified.

Why: "CoW semantics" is jargon about jargon. Describe the event the reader can observe.

## Self-check before you hand over

- Read the first paragraph of each section as the target reader. Is there any word they'd have to
  look up that isn't linked or explained?
- Is every acronym expanded or linked at first use?
- Does any sentence need a second read? Split it.
