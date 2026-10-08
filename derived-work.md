# Derived work

Where this fork has been used as source material elsewhere. This file points outward;
the analysis it points to lives in the other repository and is authoritative there.

Last checked 8 October 2026.

## X_eTaL extensions: a voxel mini game in an array language of my own

- **Repository:** [softwarewrighter/X_eTaL-extensions](https://github.com/softwarewrighter/X_eTaL-extensions)
- **Document:** [`docs/voxels.md`](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/voxels.md),
  locally `../X_eTaL-extensions/docs/voxels.md`, commit `3404df7`, 226 lines
- **Changelog entry:** `CHANGES.md`, under 2026-10-07 and 2026-10-08
- **Status:** building. Seven of eleven demos are written, tested and recorded; the
  remaining four are digging, light, water and the game itself

The document asks what a voxel game looks like when the array language is X_eTaL rather
than Dyalog APL, and when the drawing is a CPU rasteriser in Rust rather than SDL's GPU
API. It concludes that the central ideas of this repository carry over and the plumbing
does not.

### What it takes from here

| Idea in this repo | Verdict there |
|---|---|
| Chunk as a 3D array of block numbers, beside an inverted table of per-chunk facts | Carries over directly |
| Exposed faces as six rotations of the solid mask, compared with the original | Carries over; the primitives exist as `o_-`, `r_eplicate`, `w_here`, `t_able` |
| Bounding box against six frustum planes, one expression over all chunks | Carries over, in either language |
| Swept bounding box per axis with a Minkowski sum | Carries over, small arrays |
| The hundred-step ray march for picking | Carries over as one array expression |
| 3D fractal value noise, seeded | Carries over, but 2D height noise is cheaper |
| Four-byte packed vertices | Dropped: that packing exists for the GPU |
| Chunk streaming, 441 resident, two disk operations a frame | Dropped: a fixed small world instead |

Credit is given in the document to Kyle Croarkin for the approach and the
[write-up](https://homewithinnowhere.com/posts/2026-03-06-voxel-game.html). The block textures by Madeline Vergani are explicitly not used.

### Where it diverges, and why

Three decisions differ from this engine, each for a measured reason.

**Chunks are cubes, 16 by 16 by 16, not 16 by 128 by 16.** The exposed-face mask was
benchmarked in X_eTaL at both sizes:

| Chunk | Cells | Mask, ms |
|---|---|---|
| 16 by 16 by 16 | 4,096 | 1.75 |
| 16 by 128 by 16 | 32,768 | 13.25 |

Roughly 0.4 microseconds per cell, linear. An edit then remeshes one small chunk rather
than a tall column.

**Faces cross the language boundary once per chunk change, never per frame.** The bridge
carries arrays as text at about 0.35 microseconds a number, so a 256 by 256 colour frame
costs 71 ms and is ruled out, while a changed chunk's thousand faces cost about 2 ms and
the camera's six numbers cost nothing. A face crosses as five numbers: cell position,
direction 0 to 5, and block type. Rust builds the quad.

**Chunk borders are not treated as air.** This repository pads with air and draws every
border face, which the [literate walkthrough](literate.org) documents as deliberate
overdraw. Two answers were built instead. For the fixed island, faces are found over the
whole world array at once, 18,568 of 403,092, which removes the question entirely at a
cost of 55 ms inside a 0.4 second build. For the endless world, each streamed column is
meshed with a border plane borrowed from its neighbours, so seams hide. Remeshing after
an edit will use the same borrowed planes.

**The world is a list of boxed chunk arrays, not one array.** This engine keeps every
resident chunk in a single four-dimensional array and edits a block in place with
`(blk⌷chunks)←0`. X_eTaL has no indexed assignment, since values are immutable, so an
edit there rebuilds one 4,096-cell chunk at about 2 ms rather than touching the world.
The document files an ask against the language for an amend primitive that returns a new
array with some indices changed, which is APL's `@`: the same primitive this engine
leans on to place water and sand.

### The two walls, reconsidered

This fork's open problems are lighting and flowing water, both fixpoints over a tall
array, both judged too slow in array style. The X_eTaL document argues the walls are an
artefact of chunk height rather than of array style:

- **Sky light stops being a fixpoint entirely.** A running or-scan down each column marks
  every cell beneath a solid one as shaded. One scan, no iteration.
- **Block light becomes bounded.** Rounds of "the brightest neighbour minus one", blocked
  by solid blocks, at about 2 ms a round for a chunk, at most 15 rounds, run only after a
  change and spread across frames.
- **Water becomes a cellular automaton** on levels 1 to 7 over the chunks near the
  player, about 15 ms a chunk every few frames, which is the Life idiom again.

That is a direct answer to the open invitation in the author's write-up, at a smaller
chunk size than the one the invitation specifies. Both are designed and budgeted but not
yet built: they are demos 5 and 6 of the remaining work below.

### The demos, as built

Eleven in all, at `extensions/scene/demos/voxels-NAME.xtl` over a shared library
`Voxels.xtl`, run with `just demo scene voxels-NAME`. Each has a golden with headless
frames pinned where it draws, and a recording. Seven are done, every one of them
between 13:00 on 7 October and 03:00 on 8 October.

| # | Demo | State | What it showed |
|---|---|---|---|
| 1 | `voxels-chunk` | Done | A 16-cube from a height field in a few elementwise expressions; the view from above by a max-reduction down each column |
| 2 | `voxels-faces` | Done | The six-rotation mask, checked against known shapes at 1, 256, 452 and 2,048 faces a direction; 1,389 of the chunk's 10,446 possible faces, drawn as outlines |
| 3 | `voxels-solid` | Done | The same faces as shaded, depth-tested quads; 16,668 numbers crossed the bridge once |
| 4 | `voxels-world` | Done | An island of 32 chunks, 64 by 32 by 64, from value noise as three interpolations; 18,568 faces of 403,092; 0.4 s to build and mesh, about 13 ms a frame to draw |
| 5 | `voxels-walk` | Done | First person on the island: gravity, jumping, a swept box per axis, and the frustum test of all 32 chunks, all in X_eTaL |
| 6 | `voxels-endless` | Done | No edges: terrain hashed from coordinates so any column stands alone, columns built one a frame around the player and dropped behind, fog at the loaded radius and a curved horizon |
| 7 | `voxels-fly` | Done | Flying over the endless world, F to switch, level to the heading, streaming ahead one column a frame |
| 8 | `voxels-dig` | To do | The ray-march pick, breaking and placing, remeshing one chunk with its neighbours' border planes; crosshair and hotbar |
| 9 | `voxels-light` | To do | Sky light by column scan, torches spreading in rounds, a brightness per quad |
| 10 | `voxels-water` | To do | Water flowing as a cellular automaton, drawn translucent |
| 11 | `voxels-game` | To do | Gem Hunt, with all of the above, then a release step |

The library is 400 lines; the seven demos are 874 lines between them, from 28 lines for
the first to 267 for flying.

The mini game is still **Gem Hunt**: a seeded island, ten gems buried in stone, three
minutes to dig them out, water filling any hole it touches. The rules, the world and the
generation are X_eTaL; the window, the drawing and the frame clock are Rust.

### What the demos changed in the plan

Three predictions in the original analysis did not survive contact, and one assumption
held:

- **The renderer stayed on the CPU.** About 13 ms for 18,568 quads at 640 by 560 was
  fast enough, so the GPU fallback was never needed. Faster still came from drawing at
  the window's logical size on a dense display and scaling up, a quarter of the work.
- **Rust got generic quads, not voxel-specific faces.** The plan called for `f_aces!`
  taking a face list. What landed is `sc:q_uads!` with a depth buffer and `sc:f_og!`,
  with X_eTaL turning faces into quads. Later demos added a first-person camera, held
  keys and mouse motion, a curved horizon and a sky colour, plus skipping objects
  outside the view.
- **Two demos were inserted.** Walking came before flying as planned, but an endless
  world was added between them, and water was split out of the lighting demo. The count
  went from eight to eleven.
- **The bridge budget held.** Faces still cross once per chunk change and stay in Rust.

One number from the build is worth bringing back here: a lambda applied across 400,000
cells took 36 seconds, where plain reshapes of the same data took milliseconds. The
equivalent trap does not exist in Dyalog, and it is the clearest measured difference
between the two interpreters so far.

### One number to reconcile

The X_eTaL document compares its 13.25 ms mask against "the whole meshing of a 16 by 128
by 16 chunk in 0.46 ms" in Dyalog, and derives a factor of about 30. The author's own
figures, quoted in `summary.pdf` and the literate walkthrough, separate those: 0.46 ms is
the exposed-face vertex selection, and 1.8 ms is the same work once texture indices are
included. Against the fuller figure the gap is nearer 7 times than 30. The document's
conclusion is unaffected, since both numbers support meshing on change rather than every
frame.

## Analysis in this repository

The documents the above refers back to, all added on the `feat-analysis` branch:

| File | What it is |
|---|---|
| `summary.pdf` | Implementation status: what works, what is open or blocked, and why |
| `literate.org` | A literate walkthrough of the engine, with three Babel tangle targets |
| `literate.html` | The Org export of the walkthrough |
| `naming-costs.md` | How arrays are labelled for human readers, and the space and time cost |
