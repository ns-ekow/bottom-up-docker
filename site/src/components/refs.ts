// Reference data resolved at build time by tools/site-data (same resolver as tools/check-*).
import data from '../generated/refs.json';

export type Ref = {
  kind: 'corpus' | 'code' | 'exp';
  tier: string;
  label: string;
  url: string | null;
  // corpus
  source?: string; section?: string; excerpt?: string | null;
  // code
  repo?: string; slug?: string; tag?: string; commit?: string; path?: string;
  start?: number; end?: number; lang?: string; code?: string;
  // exp
  id?: string; script?: string; expected?: string | null;
};

const refs = data as Record<string, Ref>;

export function getRef(ref: string): Ref {
  const r = refs[ref.trim()];
  // Fail the build rather than publish a citation that points nowhere.
  if (!r) throw new Error(`Unresolved reference "${ref}". Run: tools/check-links`);
  return r;
}

export function splitRefs(src: string): string[] {
  return src.split(';').map((s) => s.trim()).filter(Boolean);
}

export const TIER_LABEL: Record<string, string> = {
  T1: 'T1 · authoritative', T2: 'T2 · expert secondary', T3: 'T3 · context',
  code: 'source code', exp: 'experiment',
};
