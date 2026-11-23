# Lineage 2d

2D multiplayer prototype inspired by Lineage 2 (**High Five**).  
Engine: **Godot 4.3** · authoritative dedicated server (ENet).

## Current (Cedric library + quests + HF data)

- **Start zone**: Cedric's Training Hall / library (not open meadow)
- **Starter mobs**: passive **Gremlins** only; wolves toward village path; orcs farther west
- **Pixel Human Fighter** m/f sheets + race silhouette scaffolds
- **HF Data Foundation** (6a): Talking Island runtime JSON + `DataRegistry`
- **Newbie Helper tutorial (Q255)** + **Letters of Love (Q1)** with NPC dialogs and HF rewards
- Slice 2 UI/net kept: HUD, target→engage, minimap, walk anims

See [`docs/cedric-library.md`](docs/cedric-library.md), [`docs/hf-data-sources.md`](docs/hf-data-sources.md), [`docs/hf-quests-ti.md`](docs/hf-quests-ti.md).

## Requirements

- [Godot 4.3+](https://godotengine.org/download)
- Linux / macOS / Windows
- Python 3.10+ only if regenerating runtime data (`tools/hf_ingest`)

## Controls

| Input | Action |
|-------|--------|
| WASD / arrows | Move (walk anim) |
| LMB | Select mob or **NPC** (talk opens dialog) |
| Tab | Cycle target |
| F / Space / Attack skill | Toggle engage on current mob |
| Talk button | Re-open dialog with selected NPC |
| Esc | Clear target / stop attack |
| E | Pick up nearest loot |
| I / Bag | Inventory |
| M / Map | Full map |
| R | Equip best upgrades from bag |
| 1–4 | Equip into weapon / chest / legs / head |

## Run locally

```bash
godot --path . --headless -- --server --port 7777
godot --path . --rendering-driver opengl3 -- --client --host 127.0.0.1 --port 7777 --name Alice
```

> Keep `--rendering-driver opengl3` on VMs without Vulkan.

## Suggested loop

1. Spawn in **Cedric's library** → click **Newbie Helper** → accept the Blue Gemstone mission.
2. Attack passive **Gremlin**s in the courtyard → turn in gem → talk to **Roien**.
3. Level to 2 (Gremlins or walk west past wolves) → **Darin** → Roxxy → Baulro → Darin.
4. **E** loot → **I** equip → watch gear tint on the pixel fighter.

## Layout

```
data/runtime/    HF JSON (items, npcs, quests, dialogs, …)
data/*.gd        DataRegistry, quest engine, combat helpers
tools/hf_ingest/ L2J HF → JSON converter
docs/            data sources + quest notes
scenes/ scripts/ world, player, mob, NPC, HUD
```

## Slice history

- **0** — multiplayer move
- **1** — combat / XP / loot / layered gear
- **2** — HUD, target combat, seamless map, minimap, walk anims
- **6a** — HF datapack ingest + DataRegistry (Talking Island slice)
- **quests** — Newbie Helper / Gremlin tutorial + Letters of Love
- **library** — Cedric hall start, passive Gremlins, distant wolves/orcs, pixel Human Fighter

## License

Prototype / work in progress. Datapack rights remain with their upstream L2J authors.
