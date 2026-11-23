# Lineage 2d

2D multiplayer prototype inspired by Lineage 2 (High Five chronicle).  
Engine: **Godot 4.3** · authoritative dedicated server (ENet).

## Slice 0 (this PR)

- Headless dedicated server + desktop clients
- Shared isometric meadow zone
- 2+ clients connect, spawn, and move
- Server validates movement (clients predict lightly)

Combat, loot, XP, and character create are **not** in this slice.

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (standard build; `--headless` works on the same binary)
- Linux / macOS / Windows

## Run locally (server + 2 clients)

From the repo root (directory that contains `project.godot`):

**Terminal 1 — dedicated server (headless):**

```bash
godot --path . --headless -- --server --port 7777
```

**Terminal 2 — client A:**

```bash
godot --path . --rendering-driver opengl3 -- --client --host 127.0.0.1 --port 7777 --name Alice
```

**Terminal 3 — client B:**

```bash
godot --path . --rendering-driver opengl3 -- --client --host 127.0.0.1 --port 7777 --name Bob
```

> If Vulkan init fails (common on VMs/CI), keep `--rendering-driver opengl3`.

Move with **WASD** or arrow keys. Each client follows its own avatar; both players appear in the same zone.

### CLI flags (after `--`)

| Flag | Meaning |
|------|---------|
| `--server` | Run as dedicated server |
| `--client` | Run as client (default) |
| `--host <ip>` | Server address (default `127.0.0.1`) |
| `--port <n>` | Port (default `7777`) |
| `--name <str>` | Display name above the avatar |
| `--bot` | Auto-move (for headless smoke tests) |

> Godot passes engine flags before `--`; game flags go after `--`.

**Headless smoke test (server + 2 bots):**

```bash
godot --path . --headless -- --server --port 7777 &
godot --path . --headless -- --client --name Alice --bot &
godot --path . --headless -- --client --name Bob --bot &
```

### Editor

Open the project in Godot Editor and press Play for a **client** (will try `127.0.0.1:7777`). Start the headless server first.

## Project layout

```
scenes/          bootstrap, game world, player
scripts/         networking + authoritative movement
project.godot
```

## Next slices (planned)

1. Mob + target/auto-attack + HP  
2. XP / level-up  
3. Loot → inventory  
4. Equip → stats  
…see Project docs (`mvp-plan.md`).

## License

Prototype / work in progress.
