# Lineage 2d

2D multiplayer prototype inspired by Lineage 2 (High Five).  
Engine: **Godot 4.3** · authoritative dedicated server (ENet).

## Slice 2 (current)

- L2-style HUD: **CP / HP / MP / XP** bars, target frame, skill bar, inventory with item icons
- **Target combat**: LMB or Tab to select → **F / Attack skill** to engage; server checks range + facing
- Expanded **seamless meadow** (soft far bounds), talking stone spawn, **minimap + full map (M)**
- Walk / idle bob animations for player and mobs
- Layered gear still changes appearance on equip

## Requirements

- [Godot 4.3+](https://godotengine.org/download)
- Linux / macOS / Windows

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

1. Spawn at the glowing **talking stone** (linen starter).
2. Open minimap (top-right); walk the paths east to Keltirs.
3. **Click** a Keltir → press **F** to engage → watch target frame + CP/HP.
4. **E** loot → **I** open bag → click icon to equip → armor layers update.
5. **M** for full map of the meadow.

## Layout

```
data/            items, mobs, combat
scenes/          world, player, mob, loot, character visual
scripts/         simulation + ui/
project.godot
```

## Slice history

- **0** — multiplayer move
- **1** — combat / XP / loot / layered gear
- **2** — HUD, target combat, seamless map, minimap, walk anims

## License

Prototype / work in progress.
