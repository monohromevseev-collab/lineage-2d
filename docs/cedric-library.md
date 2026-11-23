# Cedric's Training Hall / Library (starter zone)

Chronicle: **High Five** · Playable 2D layout for Human Fighter tutorial.

## Intent

Primary spawn is **inside Cedric's Training Hall / library**, not an open meadow.
Tutorial flow (Newbie Helper **30009** → Gremlin **18342** → Roien **30008**) stays in/near the hall.

## Zones (hand-authored — coords **unconfirmed**)

| Zone | Approx 2D bounds | Mobs | Aggro |
|------|------------------|------|-------|
| `cedric_library` | x −160…220, y −140…200 | **18342** Gremlin only | **Passive** (`aggro_range: 0`) |
| `village_path` | x −750…−420 | **20120** Wolf | Normal (farther west) |
| `far_wilds` | x −1200…−850 | **20130** Orc, **20006** Orc Archer | Farther than wolves |

Player spawn: `HUMAN_SPAWN ≈ (0, 40)` in hall courtyard (**unconfirmed** vs HF Cedric hall spawnlist).

Friendly NPCs:
- Helper / Roien — hall (**unconfirmed** 2D; HF Talking Island coords noted in `friendly_npcs.json`)
- Darin / Roxxy / Baulro — village path ~x −700 (**unconfirmed**)

## Runtime

- Spawns: `data/runtime/spawns.json` (`projection.status: unconfirmed`)
- Friendly NPCs: `data/runtime/friendly_npcs.json`
- Meta / gaps: `data/runtime/meta.json` → `unconfirmed`

## Art

- Pixel Human Fighter m/f: `assets/characters/human_fighter_{m,f}.png`
- Library backdrop ref: `assets/zones/cedric_library.jpg`
- Race silhouette scaffolds: `assets/races/race_lineup.png`
- Source ref (store): `media/refs/l2-races-armor-ref.png`

Gear still tints / weapon overlays on the pixel sheet so equipment stays visible.

## Quests

Q255 + Q1 unchanged (HF ids). See [`hf-quests-ti.md`](hf-quests-ti.md).
