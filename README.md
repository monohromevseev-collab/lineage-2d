# Lineage 2d

2D multiplayer prototype inspired by Lineage 2 (**High Five**).  
Engine: **Godot 4.3** · authoritative dedicated server (ENet).

## Slice 6a (current)

- **HF Data Foundation**: Talking Island runtime JSON from an L2J High Five datapack
- `DataRegistry` loads `data/runtime/*.json` (items, NPCs, drops, spawns, exp, Human Fighter)
- Toy tables replaced: real HF ids (e.g. Bearded Keltir **20481**, Short Sword **1**)
- Slice 2 UI/net kept: HUD, target→engage, minimap, walk anims, authoritative combat

See [`docs/hf-data-sources.md`](docs/hf-data-sources.md) for datapack URL/commit and unconfirmed fields.

## Requirements

- [Godot 4.3+](https://godotengine.org/download)
- Linux / macOS / Windows
- Python 3.10+ only if regenerating runtime data (`tools/hf_ingest`)

## Controls

| Input | Action |
|-------|--------|
| WASD / arrows | Move (walk anim) |
| LMB | Select mob under cursor (empty ground clears target) |
| Tab | Cycle target |
| F / Space / Attack skill (bar) | Toggle engage on **current target** |
| Esc | Clear target / stop attack |
| E | Pick up nearest loot |
| I / Bag button | Inventory (click item icons to equip) |
| M / Map button | Full map |
| R | Equip best upgrades from bag |
| 1–4 | Equip first bag item into weapon / chest / legs / head |

## Run locally

```bash
godot --path . --headless -- --server --port 7777
godot --path . --rendering-driver opengl3 -- --client --host 127.0.0.1 --port 7777 --name Alice
```

> Keep `--rendering-driver opengl3` on VMs without Vulkan. Project defaults to GL Compatibility.

### CLI flags (after `--`)

| Flag | Meaning |
|------|---------|
| `--server` / `--client` | Role |
| `--host` / `--port` | Connect |
| `--name` | Display name |
| `--bot` | Auto hunt smoke test |

## Suggested loop

1. Spawn at the glowing **talking stone** (Short Sword + Squire shirt/pants).
2. Hunt **Bearded Keltir / Elpy** nearby → engage with **F**.
3. XP follows the HF exp table; loot uses HF death-drop group chances (Adena + gear; herbs filtered).
4. **E** loot → **I** / click to equip → pAtk/pDef on the HUD update.

## Layout

```
data/runtime/    HF JSON (items, npcs, drops, spawns, exp, classes)
data/*.gd        DataRegistry + thin wrappers + combat helpers
tools/hf_ingest/ L2J HF → JSON converter
docs/            hf-data-sources.md
scenes/ scripts/ world, player, mob, loot, HUD
```

## Slice history

- **0** — multiplayer move
- **1** — combat / XP / loot / layered gear
- **2** — HUD, target combat, seamless map, minimap, walk anims
- **6a** — HF datapack ingest + DataRegistry (Talking Island slice)

## License

Prototype / work in progress. Datapack rights remain with their upstream L2J authors; we only ship a narrow generated JSON slice.
