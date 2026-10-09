# Derived work

Where this fork has been used as source material elsewhere. This file points outward;
the analysis it points to lives in the other repository and is authoritative there.

Last checked 9 October 2026.

## X_eTaL extensions: a voxel mini game in an array language of my own

- **Repository:** [softwarewrighter/X_eTaL-extensions](https://github.com/softwarewrighter/X_eTaL-extensions)
- **Document:** [`docs/voxels.md`](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/voxels.md),
  locally `../X_eTaL-extensions/docs/voxels.md`, commit `3404df7`, 226 lines
- **Changelog entry:** `CHANGES.md`, 2026-10-07 to 2026-10-09
- **Status:** building. Ten demos are written, tested and recorded. Eight of them are a
  ladder of voxel capability in a 3D world; two point the same machinery at a Rubik's
  cube. Water, light, cube buttons and the game remain

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

**An edit is a row in a list, not a write into the world.** Breaking a block here sets
the cell and raises that chunk's dirty flag. In the endless world there is nothing to
write into, since a column may not be resident and is rebuilt from its coordinates on
demand, so a dig is recorded as a row of x, y, z and block, newest first, and every
column is generated with its edits replayed over it. Persistence falls out for free:
the edit list is the save file, and this engine's component files have no counterpart
there.

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
  player, about 15 ms a chunk every few frames, which is the Life idiom again. See
  [where the water plan is written down](#where-the-water-plan-is-written-down) below.

That is a direct answer to the open invitation in the author's write-up, at a smaller
chunk size than the one the invitation specifies. Both are designed and budgeted but not
yet built: they are demos 5 and 6 of the remaining work below.

### The demos, as built

At `extensions/scene/demos/voxels-NAME.xtl`, over three shared libraries: `Voxels.xtl`
at 464 lines for the chunk work, `Endless.xtl` at 351 for the streamed world, `Rubik.xtl`
at 208 for the cube. Each demo runs with `just demo scene voxels-NAME`, has a golden with
headless frames pinned where it draws, and has a recording on the doc site.

Eight of the ten build on each other, each adding one capability to the 3D world:

| # | Demo | State | What it added |
|---|---|---|---|
| 1 | `voxels-chunk` | Done | A 16-cube from a height field in a few elementwise expressions; the view from above by a max-reduction down each column |
| 2 | `voxels-faces` | Done | The six-rotation mask, checked against known shapes at 1, 256, 452 and 2,048 faces a direction; 1,389 of the chunk's 10,446 possible faces, as outlines |
| 3 | `voxels-solid` | Done | The same faces as shaded, depth-tested quads; 16,668 numbers crossed the bridge once |
| 4 | `voxels-world` | Done | An island of 32 chunks, 64 by 32 by 64, from value noise; 18,568 faces of 403,092; 0.4 s to build and mesh, about 13 ms a frame to draw |
| 5 | `voxels-walk` | Done | First person: gravity, jumping, a swept box per axis, and the frustum test of all 32 chunks, in X_eTaL |
| 6 | `voxels-endless` | Done | No edges: terrain hashed from coordinates so any column stands alone, columns built around the player and dropped behind, fog and a curved horizon |
| 7 | `voxels-fly` | Done | Flying, level to the heading, streaming ahead; still colliding, after a first version flew through the ground |
| 10 | `voxels-dig` | Done | The ray-march pick over the columns the ray crosses, digging and building, a hotbar and a crosshair |
| 11 | `voxels-water` | To do | Water flowing as a cellular automaton, drawn translucent |
| 12 | `voxels-light` | To do | Sky light by column scan, torches spreading in rounds, a brightness per quad |
| 14 | `voxels-game` | To do | Gem Hunt, with all of the above, then a release step |

Two are not about a world at all. They reuse the voxel drawing for a Rubik's cube, where
the interesting array is a permutation rather than a grid of blocks:

| # | Demo | State | What it added |
|---|---|---|---|
| 8 | `voxels-rubik` | Done | 26 cubies drawn as voxels, while the cube itself is 54 stickers with positions and normals; each of the twelve quarter turns is a permutation computed from the geometry, checked by order: 4 for a face, 6 for `R U R' U'`, 105 for `R U` |
| 9 | `voxels-rubik-turn` | Done | One layer turning a quarter revolution, its nine cubies rotated a little more each frame by one inner product, the colours permuted once the turn completes; a twelve-move scramble, then the same moves undone back to solved |
| 13 | `rubik-buttons` | To do | Buttons for the turns, and faster animated keys |

Gaps in the numbering are the steps that were not demos: documentation, a refactor of
state into tuples, smooth streaming, a pinned language commit, and a performance gate.

The mini game is still **Gem Hunt**: a seeded island, ten gems buried in stone, three
minutes to dig them out, water filling any hole it touches.

### Where the water plan is written down

Flowing water is one of the two problems this engine's author names as not fitting array
style. The plan to do it as a cellular automaton is spread across three documents there,
in decreasing order of detail:

| Document | What it says about water |
|---|---|
| [`docs/voxels.md`, "The game"](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/voxels.md#the-game-walking-flying-building-digging-light-water) | The rule and its budget: levels 1 to 7, water falls into the air below it, otherwise spreads sideways one level lower, sources stay full. A few rotations and comparisons a tick, about 15 ms a chunk, run every few frames and only on chunks where water changed. Drawn after the solid blocks, translucent, opaque blue first |
| [`docs/plan.md`, Saga 14](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/plan.md#saga-14----voxel-game) | Step 11, `voxels-water`, and the scene it has to produce: a hill with a lake on a terrace held above the sea, where digging the ground downhill lets the water run out of the lake and fall down the slope |
| [`.agentrail/steps/012-voxels-water/prompt.md`](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/.agentrail/steps/012-voxels-water/prompt.md) | The step brief, one line, still pending |

The rule is the same six-rotation idiom as the exposed-face mask, and as Conway's Life
before it, which is the third time that one shape of expression has been reused. What
makes it affordable there and not here is scope rather than style: a 16-cube rather than
a 16 by 128 by 16 column, only the chunks where something changed, and a tick every few
frames rather than every frame.

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
- **Two demos went somewhere else entirely.** Nothing in the original analysis predicted
  a Rubik's cube. It arrived because the voxel drawing had become general enough to point
  at a different problem, and because the cube's real content is a permutation group,
  which is array work of a kind this engine never needed.

Three later corrections are worth recording, because each came from running the thing:

- **Streaming had to be split across frames.** Building a column took 40 to 68 ms, which
  showed as a pause at the world's edge. Split into blocks and mask, then faces, then
  sending, a flight's 445 frames came down to a median of 1 ms.
- **Frames had to become atomic.** Faces blinked black as the cube turned, because the
  window could show a change half applied, with a layer's cubies moved and their stickers
  not yet. The program now stages a scene and the window takes all of it at once.
- **A demo can be correct and still read as wrong.** The first cube recording turned by
  pressing keys, which changed colours instantly with no animation, and looked like
  random blinking. The fix was a separate animated demo, not a change to the cube.

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
