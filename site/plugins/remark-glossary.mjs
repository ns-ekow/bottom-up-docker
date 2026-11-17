// remark plugin: link the first use of each glossary term on a page to its glossary entry,
// with the plain-language definition shown on hover/focus. Writers don't tag anything.
//
// Skipped: headings, existing links, code blocks, imports/expressions, and component props.
// Inline code is linked only when the whole code span is a term (e.g. `pivot_root`).
// A page can opt out with `glossary: false` in its frontmatter.
import { readFileSync } from 'node:fs';
import { buildMatcher } from './glossary-match.mjs';

const SKIP = new Set(['heading', 'link', 'linkReference', 'definition', 'code', 'html', 'yaml', 'toml',
  'mdxjsEsm', 'mdxFlowExpression', 'mdxTextExpression']);

export default function remarkGlossary({ glossaryPath, base = '/' }) {
  const terms = JSON.parse(readFileSync(glossaryPath, 'utf8')).term;
  const byId = new Map(terms.map((t) => [t.id, t]));
  const matcher = buildMatcher(terms);
  const href = (id) => `${base.replace(/\/$/, '')}/glossary/#${id}`;

  const link = (id, child) => ({
    type: 'link', url: href(id), children: [child],
    data: { hProperties: { className: ['gl'], 'data-def': byId.get(id).short } },
  });

  return (tree, file) => {
    if (file.data?.astro?.frontmatter?.glossary === false) return;
    const seen = new Set();

    const walk = (node) => {
      if (!node.children) return;
      const out = [];
      for (const child of node.children) {
        if (SKIP.has(child.type)) { out.push(child); continue; }
        if (child.type === 'inlineCode') {
          const id = matcher.exact(child.value);
          if (id && !seen.has(id)) { seen.add(id); out.push(link(id, child)); } else out.push(child);
          continue;
        }
        if (child.type === 'text') {
          let last = 0;
          for (const m of matcher.find(child.value)) {
            if (seen.has(m.id)) continue;
            seen.add(m.id);
            if (m.start > last) out.push({ type: 'text', value: child.value.slice(last, m.start) });
            out.push(link(m.id, { type: 'text', value: m.text }));
            last = m.end;
          }
          if (last === 0) out.push(child);
          else if (last < child.value.length) out.push({ type: 'text', value: child.value.slice(last) });
          continue;
        }
        walk(child);
        out.push(child);
      }
      node.children = out;
    };
    walk(tree);
  };
}
