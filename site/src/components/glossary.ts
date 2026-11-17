// Glossary linking for text rendered by components (curriculum data, glossary entries), using
// the same matcher as the remark plugin that links lesson prose.
import data from '../generated/glossary.json';
import { buildMatcher } from '../../plugins/glossary-match.mjs';

export type Term = { id: string; term: string; aliases: string[]; short: string; body?: string; see?: string[];
  sources: string[]; group: string; used_in: { id: string; path: string }[] };

export const glossary = data as unknown as { groups: string[]; term: Term[] };
export const termById = new Map(glossary.term.map((t) => [t.id, t]));
const matcher = buildMatcher(glossary.term);

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const base = () => import.meta.env.BASE_URL.replace(/\/$/, '');

/**
 * Escape `text` and link the first mention of each glossary term not already in `seen`
 * (pass one Set per page so each term links once). `code` spans stay code; a code span that
 * is exactly a term is linked. `self` (a term id) is never linked; `local` makes links
 * same-page anchors (for the glossary page itself).
 */
export function linkify(text: string, seen: Set<string>, opts: { self?: string; local?: boolean } = {}) {
  const href = (id: string) => (opts.local ? `#${id}` : `${base()}/glossary/#${id}`);
  const a = (id: string, inner: string) =>
    `<a class="gl" href="${href(id)}" data-def="${esc(termById.get(id)!.short)}">${inner}</a>`;
  return text.split(/(`[^`]+`)/).map((part) => {
    if (part.length > 1 && part.startsWith('`') && part.endsWith('`')) {
      const code = part.slice(1, -1), id = matcher.exact(code);
      if (id && id !== opts.self && !seen.has(id)) { seen.add(id); return a(id, `<code>${esc(code)}</code>`); }
      return `<code>${esc(code)}</code>`;
    }
    let html = '', last = 0;
    for (const m of matcher.find(part)) {
      if (m.id === opts.self || seen.has(m.id)) continue;
      seen.add(m.id);
      html += esc(part.slice(last, m.start)) + a(m.id, esc(m.text));
      last = m.end;
    }
    return html + esc(part.slice(last));
  }).join('');
}
