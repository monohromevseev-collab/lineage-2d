# High Five data sources (slice 6a)

Chronicle lock: **Lineage II High Five only** (no Interlude / Essence / C4 tables).

## Datapack

| Field | Value |
|-------|--------|
| Project | [Shagooh/l2j-server-datapack](https://github.com/Shagooh/l2j-server-datapack) |
| Upstream lineage | L2J Server datapack — README states **master = latest High Five** |
| Commit pinned | `03897cc4ee42361304fb5a96e59bb7fba174c0a8` (2023-01-17) |
| Why this pack | Public, well-known L2J HF tree with `stats/npcs`, `stats/items`, `stats/expData.json`, `stats/chars/baseStats/HumanFighter.xml`, and `sql/spawnlist.sql` including `Talking_Island` rows |

Mirror note: official L2J hosting moves over time; this GitHub mirror is what we could fetch cleanly for reproducible ingest. Spot-checked NPC/item ids against the pack XML (not a live retail client dump).

## What 6a ingested

Talking Island **slice** only (not the full Aden client):

| Domain | Runtime file | Source path in datapack |
|--------|--------------|-------------------------|
| Items | `data/runtime/items.json` | `data/stats/items/*.xml` |
| NPCs | `data/runtime/npcs.json` | `data/stats/npcs/*.xml` |
| Drops | `data/runtime/drops.json` | NPC `<dropLists><death>` groups |
| Spawns | `data/runtime/spawns.json` | `sql/spawnlist.sql` rows with location `Talking_Island` |
| Exp | `data/runtime/exp.json` | `data/stats/expData.json` |
| Class | `data/runtime/classes.json` | `data/stats/chars/baseStats/HumanFighter.xml` |
| Provenance | `data/runtime/meta.json` | URL + commit + unconfirmed list |

NPC ids in this slice: **20481** Bearded Keltir, **20432** Elpy, **20544** Elder Keltir, **20120** Wolf, **20130** Orc, **20006** Orc Archer.

## Regenerate

```bash
git clone https://github.com/Shagooh/l2j-server-datapack.git /tmp/hf-dp/shagooh
cd /tmp/hf-dp/shagooh && git checkout 03897cc4ee42361304fb5a96e59bb7fba174c0a8

python3 tools/hf_ingest/ingest_ti.py \
  --datapack /tmp/hf-dp/shagooh \
  --out data/runtime
```

See `tools/hf_ingest/README.md`.

## Honest gaps / unconfirmed

Marked in `data/runtime/meta.json` → `unconfirmed` and on individual NPC fields:

1. **XP per kill** — datapack gives `expRate` / `sp`, not a flat “kill XP” integer. Runtime uses `xp_reward = max(1, round(expRate))` (**unconfirmed** vs full L2J `Exp` formulas). Level thresholds themselves come from HF `expData.json` (**confirmed**).
2. **2D spawn projection** — L2 `(x,y,z)` → meadow pixels with hand-tuned origin/scale (**unconfirmed**). Samples are real `Talking_Island` spawnlist rows.
3. **Mob speed / aggro / pixel attack range / attack interval** — derived heuristics (**unconfirmed**). HP / pAtk / pDef from NPC XML are **confirmed**.
4. **Combat damage** — simplified `70 * pAtk / pDef` HF-lite (**unconfirmed**; not `Formulas.calcPhysDam`).
5. **Player `base_speed_px`** — mapped from L2 run speed to meadow feel (**unconfirmed**). STR/DEX/CON/… and level HP/MP/CP gains from `HumanFighter.xml` are **confirmed**.
6. **Drop filter** — herbs and most materials/recipes/jewelry stripped for 6a (no herb/craft/jewelry systems). Remaining group chances are HF values (**confirmed** rates, filtered set).
7. **Gloves / feet** — present in item JSON and equippable via bag / R; HUD still shows the four classic slots only.
8. **No official NCSoft client files** — names/stats come from the L2J HF datapack, not a packet-sniffed retail dump.

## Spot-checks (datapack)

| Id | Name | Check |
|----|------|-------|
| 20481 | Bearded Keltir | level 1, hp≈39.7, expRate 35.268 |
| 20120 | Wolf | level 4, TI spawn rows present |
| 1 | Short Sword | pAtk 8 |
| 1146 | Squire's Shirt | pDef 33 |
| exp 1→2 | | cumulative 0 → 68 (`to_next` 68) |
