# Lineage 2d

2D multiplayer prototype inspired by Lineage 2 (**High Five**).  
Engine: **Godot 4.3** · authoritative dedicated server (ENet).

## Current (quests + HF data)

- **HF Data Foundation** (6a): Talking Island runtime JSON + `DataRegistry`
- **Newbie Helper tutorial (Q255)** + **Letters of Love (Q1)** with NPC dialogs and HF rewards
- Tutorial Gremlins (**18342**), Blue Gemstone → Recommendation → Roien
- Slice 2 UI/net kept: HUD, target→engage, minimap, walk anims

See [`docs/hf-data-sources.md`](docs/hf-data-sources.md) and [`docs/hf-quests-ti.md`](docs/hf-quests-ti.md).

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

1. Spawn at the **talking stone** → click **Newbie Helper** → accept the Blue Gemstone mission.
2. Kill nearby **Gremlin**s → turn in gem → talk to **Roien**.
3. Hunt **Bearded Keltir / Elpy** → level 2 → **Darin** → Roxxy → Baulro → Darin.
4. **E** loot → **I** equip → watch pAtk/pDef on the HUD.

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

## License

Prototype / work in progress. Datapack rights remain with their upstream L2J authors.
