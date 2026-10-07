# Derived work

Where this fork has been used as source material elsewhere. This file points outward;
the analysis it points to lives in the other repository and is authoritative there.

Last checked 7 October 2026.

## X_eTaL extensions: a voxel mini game in an array language of my own

- **Repository:** [softwarewrighter/X_eTaL-extensions](https://github.com/softwarewrighter/X_eTaL-extensions)
- **Document:** [`docs/voxels.md`](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/voxels.md),
  locally `../X_eTaL-extensions/docs/voxels.md`, commit `3404df7`, 226 lines
- **Changelog entry:** `CHANGES.md`, under 2026-10-07
- **Status:** analysis only, nothing scheduled, no demo code written yet

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

**Chunk borders are padded from the neighbours, not treated as air.** This repository
pads with air and draws every border face, which the
[literate walkthrough](literate.org) documents as deliberate overdraw. With small cubic
chunks there are far more borders, so the plan is to pad each chunk with a one-block
shell from its neighbours before the rotations, at 18 cubed, then cut back. That removes
the hidden faces and the rotation wrap-around in one move.

### The two walls, reconsidered

This fork's open problems are lighting and flowing water, both fixpoints over a tall
array, both judged too slow in array style. The X_eTaL document argues the walls are an
artefact of chunk height rather than of array style:

- **Sky light stops being a fixpoint entirely.** A running or-scan down each column marks
  every cell beneath a solid one as shaded. One scan, no iteration.
- **Block light becomes bounded.** At most 15 rounds of the same six-rotation step over a
  16-cube, about 25 ms, run only when a light or a block changes.
- **Water becomes a cellular automaton** over the chunks near the player, one flow step a
  tick, which is the Life idiom again.

That is a direct answer to the open invitation in the author's write-up, at a smaller
chunk size than the one the invitation specifies.

### The planned demos

Eight, each at `extensions/scene/demos/voxels-NAME.xtl`, each runnable, golden-tested and
recorded before the next begins. None exists yet.

1. `voxels-chunk`, a 16-cube as layers from a height field, with water
2. `voxels-faces`, the six-rotation mask and the face list, drawn as wireframe
3. `voxels-solid`, the same chunk filled and depth-tested, shaded by face direction
4. `voxels-world`, 32 chunks from noise, with per-chunk face ids and frustum culling
5. `voxels-walk`, first-person camera, gravity, jumping, swept-box collision
6. `voxels-dig`, the ray march, breaking and placing, remeshing the edited chunk
7. `voxels-light`, sky light by column scan and a torch spreading in 15 rounds
8. `voxels-game`, the mini game

The mini game is **Gem Hunt**: a seeded island 64 by 32 by 64, ten gems buried in stone,
three minutes to dig them out, water filling any hole it touches. The rules, the world
and the generation are X_eTaL; the window, the drawing and the frame clock are Rust.

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
