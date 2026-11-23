# Lineage 2d

2D multiplayer prototype inspired by Lineage 2 (High Five chronicle).  
Engine: **Godot 4.3** · authoritative dedicated server (ENet).

## Slice 1 (current)

- Headless dedicated server + desktop clients
- Human Fighter spawn at a **talking stone** meadow
- Layered ¾ character (body / armor / helm / weapon) — gear swaps change the look
- Mobs with distinct silhouettes (Keltir, Wolf, Orc Grunt), target + auto-attack, HP bars
- XP / level-up, loot drops, pickup, equip (stats + visuals update)
- Server validates movement, damage, loot, and equipment

## Requirements

- [Godot 4.3+](https://godotengine.org/download) (standard build; `--headless` works on the same binary)
- Linux / macOS / Windows

## Controls

| Input | Action |
|-------|--------|
| WASD / arrows | Move |
| F / Space / LMB | Start auto-attack (nearest / targeted mob) |
| Tab | Cycle target |
| E | Pick up nearest loot |
| R | Equip best upgrades from bag |
| 1–4 | Equip first bag item into weapon / chest / legs / head |

## Run locally (server + client)

From the repo root (directory that contains `project.godot`):

**Terminal 1 — dedicated server (headless):**

```bash
godot --path . --headless -- --server --port 7777
```

**Terminal 2 — client:**

```bash
godot --path . --rendering-driver opengl3 -- --client --host 127.0.0.1 --port 7777 --name Alice
```

Optional second client:

```bash
godot --path . --rendering-driver opengl3 -- --client --host 127.0.0.1 --port 7777 --name Bob
```

> If Vulkan init fails (common on VMs/CI), keep `--rendering-driver opengl3`. The project defaults to the GL Compatibility renderer.

### CLI flags (after `--`)

| Flag | Meaning |
|------|---------|
| `--server` | Run as dedicated server |
| `--client` | Run as client (default) |
| `--host <ip>` | Server address (default `127.0.0.1`) |
| `--port <n>` | Port (default `7777`) |
| `--name <str>` | Display name above the avatar |
| `--bot` | Auto-hunt / loot / equip (smoke tests) |

**Headless smoke test:**

```bash
godot --path . --headless -- --server --port 7777 &
godot --path . --headless -- --client --name Alice --bot &
```

### Suggested play loop

1. Spawn at the glowing talking stone (linen starter set).
2. Walk east to Keltirs — press **F** to auto-attack.
3. On kill, grab glowing loot with **E**, then **R** to equip bronze/steel upgrades.
4. Watch P.Atk / P.Def and armor layers change; push into Wolves / Orc Grunts.

## Project layout

```
data/            items, mobs, combat formulas
scenes/          bootstrap, world, player, mob, loot, character visual
scripts/         net + authoritative simulation + layered visuals
project.godot
```

## Slice history

- **0** — server + 2 clients, shared zone, move
- **1** — combat, XP, loot, equip, layered Human gear

## License

Prototype / work in progress.
