// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  integrations: [
    starlight({
      title: 'bottom-up-docker',
      description: 'Docker from the kernel up: build each layer, then read and trace the real thing.',
      customCss: ['./src/styles/course.css'],
      sidebar: [
        { label: 'Start here', items: [{ autogenerate: { directory: 'guide' } }] },
        { label: 'Modules', items: [{ autogenerate: { directory: 'modules' } }] },
      ],
    }),
  ],
});
