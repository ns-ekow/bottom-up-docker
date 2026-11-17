"""Shared helpers for the course tools: pins, citation parsing and resolution.

Citation grammar (used in <Claim src="..."> and <Walkthrough src="...">; several refs separated by ';'):
  corpus:  <source>:<file>#<anchor>                e.g. man:setns.2#description, oci-runtime:config.md#mounts
  code:    <repo>@<commit-prefix>:<path>#L<a>[-L<b>] e.g. runc@46365c6:libcontainer/nsenter/nsexec.c#L550-L570
  exp:     exp:<module>/<name>                      e.g. exp:m02/pivot-root -> labs/m02-*/experiments/pivot-root.sh
"""
import re, sqlite3, subprocess
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src"
DB = REPO / "corpus" / "cache" / "index.sqlite"
CONTENT = REPO / "site" / "src" / "content" / "docs"

CODE_RE = re.compile(r"^(?P<repo>[\w.-]+)@(?P<commit>[0-9a-f]{7,40}):(?P<path>[^#]+)#L(?P<a>\d+)(?:-L(?P<b>\d+))?$")
EXP_RE = re.compile(r"^exp:(?P<module>m\d+[a-z]?)/(?P<name>[\w.-]+)$")
CORPUS_RE = re.compile(r"^(?P<source>[\w-]+):(?P<file>[^#]+)#(?P<anchor>[\w.~-]+)$")
TAG_RE = re.compile(r"<(?P<tag>Claim|Walkthrough|Experiment)\b(?P<attrs>[^>]*?)/?>", re.S)
ATTR_RE = re.compile(r'(\w+)="([^"]*)"')

def pins() -> dict:
    """repo name (basename of owner/repo, or 'linux') -> full pinned commit."""
    out = {}
    for ln in (REPO / "pins.lock").read_text().splitlines():
        f = ln.split()
        if len(f) >= 3 and re.fullmatch(r"[0-9a-f]{40}", f[2]):
            out[f[0].split("/")[-1]] = f[2]
    return out

@dataclass
class Resolved:
    ref: str
    kind: str          # corpus | code | exp
    tier: str          # T1/T2/T3 for corpus; "code" and "exp" count as authoritative
    text: str

class RefError(Exception):
    pass

def resolve(ref: str, _pins={}) -> Resolved:
    ref = ref.strip()
    if not _pins: _pins.update(pins())
    if m := CODE_RE.match(ref):
        repo, prefix, path = m["repo"], m["commit"], m["path"]
        full = _pins.get(repo)
        if not full: raise RefError(f"unknown repo '{repo}' (not in pins.lock)")
        if not full.startswith(prefix): raise RefError(f"commit {prefix} is not the pinned {repo} commit {full[:12]}")
        try:
            blob = subprocess.run(["git", "-C", str(SRC / repo), "show", f"{full}:{path}"],
                                  check=True, capture_output=True, text=True).stdout
        except subprocess.CalledProcessError:
            raise RefError(f"{path} does not exist in {repo}@{full[:12]} (or src/{repo} not fetched)")
        lines = blob.splitlines()
        a = int(m["a"]); b = int(m["b"] or a)
        if not (1 <= a <= b <= len(lines)): raise RefError(f"lines {a}-{b} out of range: {path} has {len(lines)} lines")
        body = "\n".join(f"{i:>5}  {lines[i - 1]}" for i in range(a, b + 1))
        return Resolved(ref, "code", "code", f"{repo}@{full[:12]}:{path} lines {a}-{b}\n{body}")
    if m := EXP_RE.match(ref):
        hits = sorted(REPO.glob(f"labs/{m['module']}-*/experiments/{m['name']}.sh"))
        if not hits: raise RefError(f"no experiment script labs/{m['module']}-*/experiments/{m['name']}.sh")
        script = hits[0]; exp = script.with_suffix(".expected")
        text = f"experiment {script.relative_to(REPO)}\n--- script ---\n{script.read_text()}"
        if exp.exists(): text += f"\n--- expected output (regex per line) ---\n{exp.read_text()}"
        return Resolved(ref, "exp", "exp", text)
    if CORPUS_RE.match(ref):
        if not DB.exists(): raise RefError("corpus index missing: run tools/fetch-corpus && tools/index")
        row = sqlite3.connect(DB).execute("SELECT tier, heading, text FROM chunks WHERE cid=?", (ref,)).fetchone()
        if not row: raise RefError(f"no corpus passage '{ref}' (try: tools/ask ...)")
        return Resolved(ref, "corpus", row[0], f"{ref} [{row[0]}] {row[1]}\n{row[2]}")
    raise RefError(f"unparseable citation '{ref}'")

def content_files(paths=None):
    if paths: return [Path(p).resolve() for p in paths]
    return sorted(p for p in CONTENT.rglob("*") if p.suffix in (".md", ".mdx")) if CONTENT.exists() else []

def tags(text: str):
    """Yield (tag, attrs, match) for every Claim/Walkthrough/Experiment in a lesson."""
    for m in TAG_RE.finditer(text):
        yield m["tag"], dict(ATTR_RE.findall(m["attrs"])), m

def line_of(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1
