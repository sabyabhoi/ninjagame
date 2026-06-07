# Ninja Game

Simple top-down game built with [Odin](https://odin-lang.org/) and [Raylib](https://www.raylib.com/).

See [`docs/`](docs/README.md) for an explanation of the architecture.

## Project layout

```
src/
  main.odin, spawn.odin, player.odin   # package main — game loop and player logic
  config/config.odin                   # package config — settings and asset paths
  engine/                              # package engine — ECS, animation, assets, input, tilemap
```

## Prerequisites

Asset sprites live under `assets/` (e.g. `assets/Actor/Character/Boy/SeparateAnim/Idle.png`). Run the game from the project root so those paths resolve.

## Build and run

Using the Nix dev shell (includes Odin and Raylib):

```bash
nix develop
odin build src -out:ninjagame
./ninjagame
```

## Tests

```bash
nix develop
odin test src/engine
```
