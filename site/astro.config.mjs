// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readdirSync } from 'node:fs';
import remarkGlossary from './plugins/remark-glossary.mjs';

// Show the Modules group only once at least one lesson exists.
const hasLessons = (() => { try { return readdirSync('./src/content/docs/modules').some((f) => /\.mdx?$/.test(f)); } catch { return false; } })();

// Published under a sub-path on GitHub Pages; local dev stays at "/". See tools/publish-site.
const site = process.env.SITE_URL || 'http://localhost:4321';
const base = process.env.SITE_BASE || '/';

export default defineConfig({
  site,
  base,
  trailingSlash: 'always',
  markdown: {
    // Link the first use of each glossary term on every page (glossary.toml -> generated JSON).
    remarkPlugins: [[remarkGlossary, { glossaryPath: new URL('./src/generated/glossary.json', import.meta.url).pathname, base }]],
  },
  integrations: [
    starlight({
      title: 'bottom-up-docker',
      description: 'Docker from the kernel up: build each layer, then read and trace the real thing.',
      customCss: ['./src/styles/course.css'],
      sidebar: [
        { label: 'Curriculum', slug: 'curriculum' },
        { label: 'Glossary', slug: 'glossary' },
        { label: 'Start here', items: [{ autogenerate: { directory: 'guide' } }] },
        ...(hasLessons ? [{ label: 'Modules', items: [{ autogenerate: { directory: 'modules' } }] }] : []),
      ],
    }),
  ],
});
