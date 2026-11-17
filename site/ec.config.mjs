// Expressive Code options live here (not in astro.config.mjs) so the <Code> component can use them.
import { defineEcConfig } from '@astrojs/starlight/expressive-code';
import { pluginLineNumbers } from '@expressive-code/plugin-line-numbers';

export default defineEcConfig({
  plugins: [pluginLineNumbers()],
  defaultProps: { showLineNumbers: false },
});
