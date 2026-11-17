// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { readdirSync } from 'node:fs';

// Show the Modules group only once at least one lesson exists.
const hasLessons = (() => { try { return readdirSync('./src/content/docs/modules').some((f) => /\.mdx?$/.test(f)); } catch { return false; } })();

export default defineConfig({
  integrations: [
    starlight({
      title: 'bottom-up-docker',
      description: 'Docker from the kernel up: build each layer, then read and trace the real thing.',
      customCss: ['./src/styles/course.css'],
      sidebar: [
        { label: 'Curriculum', link: '/curriculum/' },
        { label: 'Start here', items: [{ autogenerate: { directory: 'guide' } }] },
        ...(hasLessons ? [{ label: 'Modules', items: [{ autogenerate: { directory: 'modules' } }] }] : []),
      ],
    }),
  ],
});
