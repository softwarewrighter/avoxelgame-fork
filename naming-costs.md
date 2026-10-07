# Naming costs

How arrays are labelled for human readers in this codebase, and what those labels cost
in space and time.

Prepared 7 October 2026 against commit `770e8d8`. The same analysis appears as a section
of `literate.org`, rendered in `literate.html`; this file is the standalone version.
Byte counts attributed to the author come from [*Notes on writing a voxel game in Dyalog
APL*](https://homewithinnowhere.com/posts/2026-03-06-voxel-game.html) (Kyle Croarkin, 6 March 2026). Nothing here was executed: there is no Dyalog on the machine this
was written on, so every figure is either quoted, counted from the source, or arithmetic.

## The problem APL hands you

APL gives a reader almost no help by default.

- A dfn's arguments are `⍺` and `⍵`. They have no names.
- An array carries a shape but not a schema. Nothing in the language records that column
  2 of a table holds a vertex buffer pointer.
- Primitives are symbols, so there is no verb to read either.

Every name a human reader gets in this engine is therefore a deliberate construction.
The useful way to classify those constructions is by *when the label is resolved*:
by the reader, at load time, or on every single use. Only the last class can appear in a
frame budget.

## The six mechanisms

| Mechanism | Example | Label resolved | Run-time cost |
|---|---|---|---|
| Prose column manifest | the comment block atop `avg/world.apln` | By the reader | None |
| Dfn argument headers | `⍝ ⍵ ←→ eye position` | By the reader | None |
| Numbered step comments | `⍝ (1)` … `⍝ (5)` in `Copy_chunk` | By the reader | None |
| Destructuring assignment | `(vs ic wvs wic)←Copy_chunk …` | At compile time | None |
| Load-time symbol tables | `const_loader`, `block_data.tex_z` | At startup, once | None at the use site |
| Name vectors plus index search | `cnames` with `Ci` and `Cg`; `tnames` with `Ti` | On every use | A search, and sometimes a rebuild |

### Labels the reader resolves

The chunk table's schema exists only as English, at the head of `avg/world.apln`:

```apl
⍝ -------------
⍝ Table Columns
⍝ -------------
⍝ - X and Z position (cx, cz)
⍝ - Vertex buffer pointers for solid information and water (vb, wvb)
⍝ - Index count for drawing for solid and water (idx_cnt widx_cnt)
⍝ - Whether or not it needs to be uploaded (dirty)
```

Dfn headers do the same job for arguments, and they carry more weight than comments
usually do, because there is no parameter name to read instead:

```apl
  Axis_check←{
    ⍝ ⍵ ←→ velocity where only one field is set, rest are 0
    ⍝ Returns vector (collision, velocity)
```

Both cost nothing and both can drift from the code without warning. The numbered-marker
scheme in `Copy_chunk` is the strongest form: five markers in the code correspond to five
paragraphs of explanation, so the function stays navigable without becoming verbose.

Short names are part of the same strategy rather than a lapse. `l`, `m`, `sp`, `d` and
`v` name arrays whose shape and lifetime are both visible on screen, and the
documentation of such an array is its shape. Long names appear exactly where the lifetime
is long: `chunk_info`, `view_distance`, `gradient_mask`, `water_level`.

### Labels resolved once, at load

The best-behaved mechanism here. SDL's constants are not magic numbers, but neither are
they looked up at run time. `const_loader` parses the enum and define files scraped from
the C headers and assigns them as ordinary APL variables, so `SDL_GPU_BUFFERUSAGE_VERTEX`
is a variable reference, as cheap as the integer would have been.

Block data does the same to a vector of namespaces, flattening the readable form once:

```apl
data←(
(name: 'Air' ⋄ tex: 0 0 0 0 0 0)
(name: 'Grass' ⋄ tex: 3 3 2 0 3 3)
...
)
names←⎕VGET∘'name'¨data
tex_z←∊⎕VGET∘'tex'¨data
Bi←names∘⍳∘⊆
```

The declaration reads as a table of records. The renderer only ever touches `tex_z`, a
flat numeric vector indexed arithmetically. `Load_new_chunks` applies the same idea with
`⎕SHADOW`, resolving `STONE`, `GRASS`, `SAND` and the rest through `Bi` once per call
rather than once per block.

### Labels resolved on every use

This is the only class with measurable effects.

```apl
cnames ← 'cx' 'cz' 'vb' 'wvb' 'idx_cnt' 'widx_cnt' 'dirty'
chunk_info ← ⍬⍨¨cnames
Ci ← cnames∘⍳∘⊆
  Cg←{
      ⍵≡'xz':↓⍉↑chunk_info⌷⍨⊂Ci'cx' 'cz'
      ⍵≡'enc_xz':(2*16)⊥↑chunk_info⌷⍨⊂Ci'cx' 'cz'
      chunk_info⊃⍨Ci ⍵
  }
```

A call site reads `Cg'dirty'`, about as legible as a struct field access in any other
language. Three things happen that the call site does not show. The name is enclosed. It
is searched for in a seven-element vector of character vectors. And in two cases a whole
column is *computed* rather than fetched.

## Space

### Column-major storage is a win, not a cost

The labelling scheme and the storage layout are one decision. Naming columns rather than
fields pushes the data into an inverted table, which lets Dyalog narrow each column to its
own type: coordinates to small integers, the dirty flag to a bit, buffer pointers to
full-width integers. A record-per-chunk layout cannot do this, because one array has one
type.

The author measured the effect on a nine-attribute, ten-thousand-row table:

| Layout | `⎕SIZE`, bytes |
|---|---|
| Simple matrix, 10000 by 9 | 720,040 |
| Inverted, 9 columns | 540,392 |

The first figure confirms the mechanism arithmetically. 10000 by 9 doubles is 720,000
bytes, plus a 40-byte header: every value is a double because one array has one type.
Inverting lets the three columns whose values fall under 256 become bytes, and a quarter
of the memory disappears. The real chunk table is narrower, but the direction is the same,
and the author's measured interpreter total is 22 MB at view distance 8.

### The names are free; the derived columns are not

Seven nested character vectors are a few hundred bytes, retained for the session. That is
irrelevant.

`Cg'xz'` is not. It returns 441 two-element vectors at view distance 10, each a separate
nested array with its own header, built fresh on every call and immediately garbage. The
stored equivalent, two integer columns, is two flat arrays. The label hides the
difference: `Cg'xz'` and `Cg'dirty'` are identical at the call site, and one of them is a
constructor.

### Where space is traded away deliberately

Two places pay space to buy time, and both are labelled lookups over large collections
rather than over column names.

```apl
mapi←(1500⌶)⍬ ⍝ (2*16)⊥x y
```

`(1500⌶)` asks the interpreter to maintain a hash table over the chunk index, so
`mapi⍳key` stops being a linear scan. The table is extra retained memory, taken
knowingly, because this vector grows with every chunk ever generated. The text subsystem
makes the same trade with a checksum column that exists only to answer whether a string
or its colour changed since the last frame:

```apl
update_mask←(table⊃⍨Ti'hash')≠hashes←chksum↓⍉↑⊃∘table¨Ti'color' 'str'
```

One extra numeric column, in exchange for not re-rasterising unchanged text.

The contrast with the column-name tables is the point. Where the labelled collection is
large, the author pays space for a hash. Where it is seven items long, he pays a linear
search. Both choices are right.

## Time

### The name search is negligible, and should not be optimised

`Ci'vb'` is an enclose and a find over seven short character vectors. Across the engine
there are 26 getter call sites and 9 index call sites, of which the per-frame paths reach
roughly a dozen. A dozen seven-element searches against a 16.6 ms budget is not worth
discussing, and replacing the names with integer constants would buy nothing while giving
up the only schema the file has.

### The rebuilt column is the real cost

Counting calls in the two functions that run every frame:

| Function | `Cg'xz'` | `Cg'enc_xz'` | Stored-column fetches |
|---|---|---|---|
| `Draw_chunks` | 3 | 0 | 5 |
| `Update_range` | 3 | 1 | 3 |

Six reconstructions of the coordinate-pair list per frame, each a mix, a transpose and a
split over every loaded chunk, plus one base-65536 fold. None is cached, and within a
frame none can differ except across the load and unload step in the middle of
`Update_range`. At 60 frames per second and 441 resident chunks that is on the order of
160,000 small nested arrays created and discarded per second, to answer a question whose
answer changes at most twice a frame.

The downstream effect is larger than the construction. The set operations consume that
nested form:

```apl
range←(ax az ⋄ )+,∘.,⍨(⍳1+2×view_distance)-view_distance
new←range~Cg'xz'
old←range~⍨Cg'xz'
m←~old∊⍨Cg'xz'
```

Three set operations over nested cells, where each comparison is a small array comparison
rather than one step of a vectorised pass over an integer vector. The integer form of the
same key already exists as `enc_xz`, and is already trusted enough to be the on-disk
index.

## Three changes that keep every label and remove the cost

1. **Hoist the derived column.** Fetch `xz←Cg'xz'` once at the top of `Draw_chunks`, and
   once either side of the load and unload step in `Update_range`. Six constructions
   become three, and the call sites keep reading as names.
2. **Do the set arithmetic on the encoded key.** Build `range` encoded in base 65536 and
   compare against `Cg'enc_xz'`, so the three set operations run over a flat integer
   vector. Decode only the survivors, which are few.
3. **Make the derivation visible in the name.** `Cg'xz'` and `Cg'dirty'` differ by orders
   of magnitude and read identically. A convention separating stored columns from computed
   ones, or a cached column invalidated by the load and unload step, would make the cost
   legible where someone is deciding whether to call it three times.

None of these changes the readability of the code, which is the test any change here has
to pass.

## Summary

| Labelling technique | Space | Time |
|---|---|---|
| Comments and dfn headers | Zero | Zero |
| Load-time symbol tables | One flat array per label set | Zero at the use site |
| Column names with index search | A few hundred bytes, retained | Negligible, about a dozen searches a frame |
| Named getter over a derived column | Hundreds of small allocations per call | The dominant labelling cost, six rebuilds a frame |
| Hashed index, `(1500⌶)` | A hash table, deliberately | Turns a linear scan into a lookup |
| Checksum column | One numeric column | Avoids re-rasterising unchanged text |

Labels resolved by the reader are free. Labels resolved at load are free at the point of
use. Labels resolved at run time cost a search, which does not matter, and labels that
hide a derivation cost the derivation, which does.

The labels earn their cost regardless. The schema-free array is what makes the rest of
this engine possible: one compress unloads a chunk, one inner product culls the world.
The names are what let a reader know which column the compress was applied to.
