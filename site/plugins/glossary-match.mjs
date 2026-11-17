// Shared term matcher for the glossary: used by the remark plugin (lesson pages) and by the
// glossary page itself, so a term is recognized the same way everywhere.
//
// Rules (mirroring glossary.toml's header): aliases match as whole words; an ALL-CAPS alias
// (PID, OCI, NAT) matches case-sensitively, any other alias ignores case. Longer aliases win
// ("PID namespace" before "PID").

const isAcronym = (a) => a === a.toUpperCase() && /[A-Z]/.test(a);
const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export function buildMatcher(terms) {
  const byAlias = new Map(); // lowercased alias -> { id, alias, strict }
  for (const t of terms) for (const a of t.aliases) byAlias.set(a.toLowerCase(), { id: t.id, alias: a, strict: isAcronym(a) });
  const alternation = [...byAlias.values()].map((x) => x.alias).sort((a, b) => b.length - a.length).map(escape).join('|');
  const re = new RegExp(`(?<![\\w-])(${alternation})(?![\\w-])`, 'gi');

  /** Find term matches in a string: [{ start, end, text, id }], respecting case rules. */
  function find(text) {
    const out = [];
    for (const m of text.matchAll(re)) {
      const hit = byAlias.get(m[1].toLowerCase());
      if (!hit || (hit.strict && m[1] !== hit.alias)) continue;
      out.push({ start: m.index, end: m.index + m[1].length, text: m[1], id: hit.id });
    }
    return out;
  }

  /** Whole-string match (for inline code like `pivot_root`). */
  function exact(text) {
    const hit = byAlias.get(text.toLowerCase());
    return hit && (!hit.strict || text === hit.alias) ? hit.id : null;
  }

  return { find, exact };
}
