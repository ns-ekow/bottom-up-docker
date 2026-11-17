// Curriculum data generated from curriculum.toml by tools/site-data. Never edit content here.
import data from '../generated/curriculum.json';

export type ReadPath = { ref: string; repo: string; path: string; url: string };
export type Source = { id: string; title: string; tier: string };
export type Module = {
  id: string; part: string; week: number; title: string; question: string; objectives: string[];
  experiment: string; build: string; read: ReadPath[]; trace: string; sources: Source[];
  status: 'planned' | 'drafting' | 'review' | 'published'; lesson: string | null;
};
export type Part = { id: string; title: string; summary: string };

export const curriculum = data as unknown as {
  title: string; weeks: string; anatomy: string[]; out_of_scope: string[]; part: Part[]; module: Module[];
};

export const modulesIn = (part: string) => curriculum.module.filter((m) => m.part === part);

export function getModule(id: string): Module {
  const m = curriculum.module.find((x) => x.id === id);
  if (!m) throw new Error(`No module "${id}" in curriculum.toml`);
  return m;
}

export const STATUS_LABEL = { planned: 'planned', drafting: 'drafting', review: 'in review', published: 'ready' };

export function href(path: string) {
  return `${import.meta.env.BASE_URL.replace(/\/$/, '')}/${path.replace(/^\//, '')}`;
}
