# Ninja Game

Simple top-down game built with [Odin](https://odin-lang.org/) and [Raylib](https://www.raylib.com/).

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
odin test src
```
