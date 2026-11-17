# Site (Astro Starlight)

```bash
cd site
npm ci            # pinned versions from package-lock.json
npm run dev       # http://localhost:4321, live reload
npm run build     # static site -> dist/
```

Both run `tools/site-data` first, which resolves every `<Claim>`, `<Walkthrough>` and `<Experiment>`
reference using the same resolver as `tools/check-links`. An unresolved reference fails the build.
Walkthrough code is read from `src/` at the pinned commit, so run `tools/fetch-src` first.

Lessons live in `src/content/docs/modules/`. Import components with
`import { Claim, Walkthrough, Note, Experiment, Graph } from '@components';`

| Component | Use |
|---|---|
| `<Claim src="ref; ref" />` | Citation after a sentence; popover shows tier, link and (for openly licensed sources) the passage |
| `<Walkthrough src="repo@commit:path#La-Lb" title mark="560">` | Pinned code with file line numbers, annotations beside it |
| `<Note lines="557-558">` | One annotation; hovering or focusing highlights those lines |
| `<Experiment id="m00/pid-namespace" />` | Script from `labs/`, how to run it, the expected output |
| `<Graph svg="graphs/x.svg" caption from="command" />` | Deterministic graph from `tools/graphs/` |
