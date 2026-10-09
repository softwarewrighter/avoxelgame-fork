# A fork, with reading notes

This is a fork of [namgyaaal/avoxelgame](https://github.com/namgyaaal/avoxelgame), Kyle
Croarkin's voxel game in Dyalog APL, MIT licensed. **No code has been changed.**

You are reading `feat-analysis`, the default branch of this fork. It adds five documents
and a `tangle/` directory, and no code. The author's code is on `main`, which mirrors
upstream.

| Document | What it is |
| --- | --- |
| [`summary.pdf`](summary.pdf) | Implementation status: what works, what is open or blocked, and why |
| [`literate.org`](literate.org) | A literate walkthrough of the engine, every block quoted from the source and annotated. Three Babel tangle targets |
| [`literate.html`](literate.html) | The Org export of the walkthrough, for reading in a browser |
| [`naming-costs.md`](naming-costs.md) | How arrays are labelled for human readers, and what the labels cost in space and time |
| [`derived-work.md`](derived-work.md) | Where this engine has been used as source material elsewhere |

The notes are a reading of the code, not a critique of it, and the measurements they
quote are the author's own. His write-up is the place to start:
[Notes on writing a voxel game in Dyalog APL](https://homewithinnowhere.com/posts/2026-03-06-voxel-game.html).

## Where this led

The notes fed a second project. [X_eTaL-extensions](https://github.com/softwarewrighter/X_eTaL-extensions)
rebuilds these ideas in X_eTaL, an array language of my own, drawn by a CPU rasteriser in
Rust instead of SDL. Ten `voxels-*` demos exist so far, each one runnable, golden-tested
and recorded.

Eight of them are a ladder, each adding one capability to a voxel world: a chunk as an
array, the exposed-face mask by six rotations, solid shaded faces, an island of 32
chunks, walking in the first person, an endless world under a curved horizon, flying,
then digging and building. Two are not about a world at all. They point the same voxel
drawing at a Rubik's cube, where 26 cubies are voxels but the cube itself is 54 stickers
and twelve permutations.

Still to come: water flowing as a cellular automaton, lighting, on-screen controls for
the cube, and the game. The water plan is the interesting one here, since flowing water
is one of the two problems this engine's author names as not fitting array style; it is
written up in
[`docs/voxels.md`](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/voxels.md#the-game-walking-flying-building-digging-light-water)
and scheduled in
[`docs/plan.md`](https://github.com/softwarewrighter/X_eTaL-extensions/blob/main/docs/plan.md#saga-14----voxel-game).

[`derived-work.md`](derived-work.md) has the detail, including what the build changed in
the plan and what it measured.

To get the game itself, with none of this, use `main`:

```
git clone -b main https://github.com/softwarewrighter/avoxelgame-fork.git
```

---

## Original README

![Cover](./images/cover.png)

# A Voxel Game

This started off as a bet with myself that APL notation would provide an easier way to make a voxel game.

This is highly experimental and buggy.

## Controls

- W-A-S-D to move
- Space to jump
- Mouse to move the camera
- Q to quit
- I to toggle render information
- H to hide/unhide UI
- F for fast noclip mode
- L to lock and unlock the mouse while in-game
- 1-5 to select different blocks to place

# Requirements

- Dyalog APL 20.0
- A C Compiler
- CMake
- Vulkan, DirectX12 or Metal graphics are required. For more information, check [here](https://wiki.libsdl.org/SDL3/CategoryGPU#system-requirements)
- sdl3, sdl3_ttf and sdl3_image (MacOS with `brew`)

# Instructions

## Running on MacOS or Linux

After installing dependencies and cloning, make sure you build and install LSE.
e.g.,
```
cd lse 
mkdir build
cd build
cmake ..
make 
make install
```

This should install `libLSE.dylib` on macOS and `libLSE.so` on Linux in `./libs/` alongside the relevant SDL3 library files. 

After that you should be able to run with `./main.apls`

Some Linux users may have `dyalogscript` located in a different directory. If that's the case, the shebang in `main.apls` should be replaced with the path specified by `which dyalogscript`

## Running on Windows

Compiling everything on Windows is a bit more tricky and is best done with finding the SDL3 dev libraries provided on libsdl3 releases with cmake-gui.

.dlls are provided as a release [here](https://github.com/namgyaaal/avoxelgame/releases/tag/Supplementary) which can be placed in a folder `./libs` on the directory this repository.

Afterwards, the game can be played through a Dyalog session like so:

```apl
]cd <ROOT DIRECTORY>
]link.create # ./avg
Run
state.Play
```

# Compiling Shaders

Source code that gets compiled to different shader formats is in `./shaders/glsl`

Shaders come bundled with this repo. However, if you want to modify them, edit the glsl shaders and run `./compile_shaders.sh` 

Note that this requires the DirectX Shader Compiler, glslc and spirv-cross.

# Known Issues

- There are significant performance regressions on Windows being worked on.
- DirectX12 backend is currently not supported on Windows.
- You currently can't play multiple times in the same session.
    - Known to syserror 999 !
    - There's probably memory leaks somewhere !

# Credits

Textures by Madeline Vergani ([@RubenVerg](https://github.com/RubenVerg))
