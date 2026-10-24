# rrll — Cellular Automata

A browser-based artificial-life simulation. Cells drift, burn energy, eat food,
interact, and reproduce with mutated genes; the population is rendered as a
metaball field. On a timer the universe respawns with randomized parameters.

## Files

- `index.html` — host page. Loads the sketch, stretches the canvas to the
  viewport with CSS, injects the runtime `size()`, corrects mouse coordinates
  for the CSS scale, guards the draw loop with real error logging, and provides
  the control panel (hover the right edge).
- `rr2ll2ia3.pde` — the simulation, a Processing sketch.
- `processing.min.js` — Processing.js 1.4.8, vendored and served same-origin
  (no CDN dependency, real error stacks).
- `xx` — an older JavaScript port of the sketch. Not loaded by the page; kept
  for reference.

## Running

Static files, no build step. Serve the directory over HTTP and open
`index.html` (the page fetches the `.pde`, so `file://` will not work):

```
python3 -m http.server
```

The site is also served via GitHub Pages from the default branch.

## Controls

The panel slides in from the right edge and drives the live sketch through a
`setParam`/`setFlag` bridge:

- Sliders: mutation, mutation range, interaction radius, cell radius,
  reproduction threshold, food density, metaball threshold, refresh interval
  (min/max seconds), target fps.
- `lock values on refresh` — a refresh respawns cells but keeps the panel
  values instead of randomizing them.
- `auto refresh` — the timed respawn on/off.
- `respawn now` / `randomize all` — immediate respawn, with or without
  re-randomizing parameters.
- Readout: universe size, live cell count, current refresh interval, measured
  fps.

## Simulation model

Each cell has a gene, a mutation rate, an individual max speed, and energy.
Movement is a random walk; cells slow down near the mouse. Energy drains over
time, is gained from interactions and from food particles; a cell with enough
energy can reproduce, passing on a mutated gene. Rendering is a metaball
field over the live cells (bounding-box accumulation, squared distances).

## Notes

- Processing.js quirks are worked around deliberately: `PVector` instance
  methods are not chained, sketch functions are not called unqualified inside
  class bodies, and `nf(,0,2)` leading-zero gaps are handled by a local
  `fmt2()` helper.
- The internal render scale is 1.0; the page fills the window with CSS so the
  simulation cost stays constant.
